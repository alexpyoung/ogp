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
    private let crawler = WebCrawler()
    private var cookies: [HTTPCookie] = []
    var store: PDFStore?
    
    func didAuthenticate(using view: WKWebView) {
        self.state = .authenticated
    }

    private func crawl(using view: WKWebView) {
        self.state = .crawling
        if let start = URL(string: "https://lmsdocs.fdnycloud.org/dcu/web/ems-og-procedures") {
            self.crawler.start(url: start, view: view) { results in
                Task {
                    do {
                        self.cookies = await view.cookies()
                        for result in results {
                            guard let url = URL(string: result) else { continue }
                            let request = URLRequest(url: url, cookies: self.cookies)
                            let (data, _) = try await URLSession.shared.data(for: request)
                            let _ = try self.store?.save(
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
    }
}
