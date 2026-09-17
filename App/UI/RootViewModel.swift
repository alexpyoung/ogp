//
//  RootViewModel.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import Combine
import SwiftData
import SwiftUI

enum AppState {
    case uninitialized
    case idle
    case indexing(Float)
    case crawling(Float)
    case downloading(Float)
    case error(Error)
}

@MainActor
final class RootViewModel: ObservableObject {
    
    @Published private(set) var state: AppState = .uninitialized
    let auth: AuthenticationService
    let repo: DocumentRepository
    private let database: DatabaseManager
    let baseURL = URL(string: "https://lmsdocs.fdnycloud.org/")
    private let tokenizer: PDFTokenizer
    
    init(database: DatabaseManager = .shared,
         repo: DocumentRepository = .shared,
         auth: AuthenticationService
    ) {
        self.database = database
        self.auth = auth
        self.repo = repo
        self.tokenizer = PDFTokenizer(repo: repo)
        Task {
            try await auth.authenticate()
            if self.repo.hasFiles {
                self.state = .idle
            } else {
                await self.crawl()
            }
        }
    }

    func crawl() async {
        do {
            self.state = .crawling(0)
            guard let base = self.baseURL,
                  let start = URL(string: "/dcu/web/ems-og-procedures", relativeTo: base)
            else { throw URLError(.badURL) }
            let exclusions = [
                URL(string: "/dcu/web/user/logout")
            ].compactMap { $0 }
            try await self.auth.authenticate()
            let loader = await HTMLLoader(cookies: self.auth.cookies)
            let crawler = WebCrawler(base: base, exclusions: exclusions, loader: loader)
            crawler.$progress
                .map { AppState.crawling($0) }
                .assign(to: &self.$state)
            let (results, existing) = await (
                try crawler.start(url: start),
                try self.repo.documents().map { $0.remotePath }
            )
            let targets = results.subtracting(Set(existing))
                .compactMap { URL(string: $0, relativeTo: self.baseURL)}
            try await self.download(urls: targets)
        } catch {
            self.state = .error(error)
        }
    }
    
    func sync() async {
        do {
            let urls = try await self.repo.documents()
                .compactMap { URL(string: $0.remotePath, relativeTo: self.baseURL) }
            try await self.download(urls: urls)
            try await self.auth.authenticate()
        } catch {
            self.state = .error(error)
        }
    }
    
    func index() async {
        do {
            self.state = .indexing(0)
            // TODO: Delete FTS records
            _ = try await self.repo.deleteAll(of: DocumentToken.self)
            _ = try await self.repo.deleteAll(of: DocumentMetadata.self)
            let documents = try await self.repo.documents()
            let total = Float(documents.count)
            for (index, document) in documents.enumerated() {
                try await self.index(document: document)
                self.state = .indexing(Float(index) / total)
            }
            self.state = .idle
        } catch {
            self.state = .error(error)
        }
    }
    
    private func index(document: Document) async throws {
        let tokens = self.tokenizer.tokenize(document: document)
        try await self.repo.save(tokens: tokens)
        if let metadata = MetadataBuilder.shared.build(id: document.id, tokens: tokens) {
            try await self.repo.save(metadata: metadata)
        }
    }
    
    private func download(urls: [URL]) async throws {
        let session = self.auth.session()
        let total = Float(urls.count)
        for (index, url) in urls.enumerated() {
            let (data, _) = try await session.data(from: url)
            _ = try await self.repo.save(data: data, from: url.path)
            self.state = .downloading(Float(index + 1) / total)
        }
        self.state = .idle
    }
}
