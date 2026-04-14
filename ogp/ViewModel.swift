//
//  ViewModel.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftUI
import WebKit

enum AppState {
    case authenticating
    case crawling
    case list([URLRequest])
}

@MainActor
final class ViewModel: ObservableObject {
    @Published private(set) var state: AppState = .authenticating
    private let crawler = WebCrawler()
    private var cookies: [HTTPCookie] = []
    
    func didAuthenticate(using view: WKWebView) {
        self.state = .crawling
        if let start = URL(string: "https://lmsdocs.fdnycloud.org/dcu/web/ems-og-procedures") {
            self.crawler.start(url: start, view: view) { results in
                Task {
                    self.cookies = await view.cookies()
                    let requests = results
                        .compactMap(URL.init)
                        .map { URLRequest(url: $0, cookies: self.cookies) }
                    self.state = .list(requests)
                }
            }
        }
    }
}
