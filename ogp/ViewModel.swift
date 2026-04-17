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
    case authenticated
    case error(Error)
}

@MainActor
final class ViewModel: ObservableObject {
    
    @Published private(set) var state: AppState = .unauthenticated
    private var crawler: WebCrawler?
    private var cookies: [HTTPCookie] = []
    private let store: PDFStore
    
    init(store: PDFStore) {
        self.store = store
    }
    
    func didAuthenticate(using cookies: [HTTPCookie]) async {
        self.cookies = cookies
        self.crawler = await WebCrawler(cookies: cookies)
        self.state = .authenticated
    }
    
    func data(for pdf: PDFModel) throws -> Data? {
        return try self.store.load(for: pdf.id)
    }

    private func crawl() {
        self.state = .crawling
        let url = "https://lmsdocs.fdnycloud.org/dcu/web/ems-og-procedures"
        self.crawler?.start(url: url) { results in
            do {
                for result in results {
                    guard let url = URL(string: result) else { continue }
                    let request = URLRequest(url: url, cookies: self.cookies)
                    let (data, _) = try await URLSession.shared.data(for: request)
                    let _ = try self.store.save(
                        filename: url.lastPathComponent,
                        data: data,
                        remoteUrl: url
                    )
                }
                self.state = .authenticated
            } catch {
                self.state = .error(error)
            }
        }
    }
}
