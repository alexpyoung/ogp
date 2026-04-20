//
//  WebCrawler.swift
//  ogp
//
//  Created by Alex Young on 4/13/26.
//

import Foundation
import SwiftSoup
import WebKit

final class WebCrawler: NSObject, ObservableObject {
    
    private var queue: Set<String> = []
    private var visited: Set<String> = []
    private let view: AsyncWKWebView
    private var enqueuedCount: Float = 0
    @Published private(set) var progress: Float = 0
    let base: URL
    
    @MainActor
    init(base: URL, cookies: HTTPCookieStorage = HTTPCookieStorage.shared) async {
        self.base = base
        self.view = await AsyncWKWebView(cookies: cookies)
        super.init()
    }
    
    func start(url: URL) async throws -> Set<String> {
        await self.insert(url: url.absoluteURL.standardized.absoluteString)
        return try await self.next([])
    }
    
    private func insert(url: String) async {
        self.queue.insert(url)
        self.enqueuedCount += 1
        await MainActor.run {
            let total = enqueuedCount + Float(self.queue.count)
            self.progress = enqueuedCount / total
        }
    }
    
    fileprivate func next(_ results: Set<String>) async throws -> Set<String> {
        if self.queue.isEmpty { return results }
        var results = results
        let url = self.queue.removeFirst()
        guard isVisitable(url: url) else { return try await self.next(results) }
        self.visited.insert(url)
        let html = try await self.view.html(for: url)
        let document = try SwiftSoup.parse(html)
        for anchor in try document.select("a[href]") {
            let href = try anchor.attr("href")
            if href.lowercased().contains(".pdf") {
                if let url = href.removingPercentEncoding {
                    results.insert(url)
                } else {
                    throw URLError(.unsupportedURL, userInfo: [
                        NSURLErrorFailingURLErrorKey: href
                    ])
                }
            } else if let url = URL(string: href)?.clean(),
                      url.host == self.base.host,
                      !self.visited.contains(href) {
                await self.insert(url: url.absoluteString)
            }
        }
        return try await self.next(results)
    }
    
    private func isVisitable(url: String) -> Bool {
        let exclusionPaths: Set<String> = [
            "/dcu/web/user/logout"
        ]
        guard let url = URL(string: url) else { return false }
        return !self.visited.contains(url.absoluteString) &&
        !exclusionPaths.contains(url.path) &&
        url.lastPathComponent.hasPrefix("ems-og")
    }
}

private final class AsyncWKWebView: NSObject {
    
    private var view: WKWebView
    fileprivate var continuation: CheckedContinuation<String, Error>?
    
    @MainActor
    init(cookies: HTTPCookieStorage) async {
        let view = await WKWebView(cookies: cookies)
        self.view = view
        super.init()
        view.navigationDelegate = self
    }
    
    @MainActor
    func html(for url: String) async throws -> String {
        return try await withCheckedThrowingContinuation {
            guard let url = URL(string: url) else {
                $0.resume(throwing: URLError(.badURL, userInfo: [
                    NSURLErrorFailingURLErrorKey: url,
                ]))
                return
            }
            self.continuation = $0
            self.view.load(URLRequest(url: url))
        }
    }
}

private extension WKWebView {
    
    convenience init(cookies: HTTPCookieStorage) async {
        let dataStore = WKWebsiteDataStore.default()
        for cookie in cookies.cookies ?? [] {
            await dataStore.httpCookieStore.setCookie(cookie)
        }
        let config = WKWebViewConfiguration()
        config.websiteDataStore = dataStore
        self.init(frame: .zero, configuration: config)
    }
}

extension AsyncWKWebView: WKNavigationDelegate {
    
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
}
