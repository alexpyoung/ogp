//
//  OGP+WKWebView.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import WebKit

extension WKWebView {
    
    func cookies() async -> [HTTPCookie] {
        await withCheckedContinuation { continuation in
            self.configuration.websiteDataStore.httpCookieStore.getAllCookies {
                continuation.resume(returning: $0)
            }
        }
    }
}
