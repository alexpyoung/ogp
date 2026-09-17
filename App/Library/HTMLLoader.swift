//
//  HTMLLoader.swift
//  ogp
//
//  Created by Alex Young on 4/20/26.
//

import Foundation
import WebKit

protocol HTMLProvider {

    func string(for url: String) async throws -> String
}

@MainActor
final class HTMLLoader: NSObject {
    
    private let view: WKWebView
    private var continuation: CheckedContinuation<String, Error>?
    
    init(cookies: [HTTPCookie]) async {
        let dataStore = WKWebsiteDataStore.default()
        for cookie in cookies {
            await dataStore.httpCookieStore.setCookie(cookie)
        }
        let config = WKWebViewConfiguration()
        config.websiteDataStore = dataStore
        self.view = WKWebView(frame: .zero, configuration: config)
        super.init()
        self.view.navigationDelegate = self
    }
}

extension HTMLLoader: HTMLProvider {

    func string(for url: String) async throws -> String {
        return try await withCheckedThrowingContinuation {
            if let url = URL(string: url) {
                self.continuation = $0
                self.view.load(URLRequest(url: url))
            } else {
                $0.resume(throwing: URLError(.badURL, userInfo: [
                    NSURLErrorFailingURLErrorKey: url,
                ]))
            }
        }
    }
}

extension HTMLLoader: WKNavigationDelegate {
    
    func webView(_ view: WKWebView, didFinish _: WKNavigation) {
        view.evaluateJavaScript("document.documentElement.outerHTML") { result, error in
            if let error = error {
                self.continuation?.resume(throwing: error)
            } else if let string = result as? String {
                self.continuation?.resume(returning: string)
            } else {
                let error = DecodingError.typeMismatch(String.self, .init(
                    codingPath: [],
                    debugDescription: "JavaScript evaluation did not return a String"
                ))
                self.continuation?.resume(throwing: error)
            }
            self.continuation = nil
        }
    }
    
    func webView(_ _: WKWebView, didFail _: WKNavigation, withError error: Error) {
        self.continuation?.resume(throwing: error)
        self.continuation = nil
    }
    
    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation, withError error: Error) {
        self.continuation?.resume(throwing: error)
        self.continuation = nil
    }
}
