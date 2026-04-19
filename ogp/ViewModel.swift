//
//  ViewModel.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftData
import SwiftUI
import WebKit

enum AppState {
    case unauthenticated
    case crawling
    case downloading(Float)
    case authenticated
    case error(Error)
}

@MainActor
final class ViewModel: ObservableObject {
    
    @Published private(set) var state: AppState = .unauthenticated
    private var crawler: WebCrawler?
    private let store: PDFStore
    let baseURL = URL(string: "https://lmsdocs.fdnycloud.org")
    
    init(store: PDFStore) {
        self.store = store
    }
    
    func didAuthenticate(using cookies: [HTTPCookie]) async {
        cookies.forEach(HTTPCookieStorage.shared.setCookie)
        guard let base = self.baseURL else { return }
        self.crawler = await WebCrawler(base: base)
        do { try await self.crawl() }
        catch { self.state = .error(error) }
    }
    
    func data(for pdf: PDFModel) throws -> Data? {
        return try self.store.load(for: pdf.id)
    }

    private func crawl() async throws {
        self.state = .crawling
        guard let crawler = self.crawler,
              let start = URL(string: "/dcu/web/ems-og-procedures", relativeTo: self.baseURL)
        else { return }
        let results = try await crawler.start(url: start)
        try await self.download(pdfs: results)
    }
    
    private func download(pdfs: Set<URL>) async throws {
        let session = URLSession(cookies: HTTPCookieStorage.shared)
        for (index, url) in pdfs.enumerated() {
            let (data, _) = try await session.data(from: url)
            let _ = try self.store.save(
                filename: url.lastPathComponent,
                data: data,
                remoteUrl: url
            )
            self.state = .downloading(Float(index + 1) / Float(pdfs.count))
        }
        self.state = .authenticated
    }
}
