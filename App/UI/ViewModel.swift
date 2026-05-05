//
//  ViewModel.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import Combine
import GRDB
import SwiftData
import SwiftUI
import WebKit

enum AppState {
    case uninitialized
    case unauthenticated
    case crawling(Float)
    case downloading(Float)
    case authenticated
    case error(Error)
}

@MainActor
final class ViewModel: ObservableObject {
    
    @Published private(set) var state: AppState = .uninitialized
    let repo: DocumentRepository
    private let database: DatabaseManager
    let baseURL = URL(string: "https://lmsdocs.fdnycloud.org/")
    private var cancellables = Set<AnyCancellable>()
    
    init(database: DatabaseManager = .shared, repo: DocumentRepository) {
        self.database = database
        self.repo = repo
    }

    func didAuthenticate(using cookies: [HTTPCookie]) async {
        cookies.forEach(HTTPCookieStorage.shared.setCookie)
        self.state = .authenticated
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
            let loader = await HTMLLoader(cookies: HTTPCookieStorage.shared)
            let crawler = WebCrawler(base: base, exclusions: exclusions, loader: loader)
            crawler.$progress
                .sink { self.state = .crawling($0) }
                .store(in: &cancellables)
            let results = try await crawler.start(url: start)
            let existing = Set(try await self.repo.all().map { $0.remotePath })
            let targets = results.subtracting(existing).compactMap { URL(string: $0, relativeTo: self.baseURL)}
            try await self.download(pdfs: targets)
        } catch {
            self.state = .error(error)
        }
    }
    
    func sync() async {
        do {
            let urls = try await self.repo.all().compactMap { URL(string: $0.remotePath, relativeTo: self.baseURL) }
            try await self.download(pdfs: urls)
        } catch {
            self.state = .error(error)
        }
    }
    
    private func download(pdfs: [URL]) async throws {
        let session = URLSession(cookies: HTTPCookieStorage.shared)
        for (index, url) in pdfs.enumerated() {
            let (data, _) = try await session.data(from: url)
            let _ = try await self.repo.save(data: data, from: url.path)
            self.state = .downloading(Float(index + 1) / Float(pdfs.count))
        }
        self.state = .authenticated
    }
}
