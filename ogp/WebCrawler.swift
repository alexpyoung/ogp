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
    private var queue: Set<URL> = []
    private var visited: Set<String> = []
    private var pdfs: Set<URL> = []
    private let view: AsyncWKWebView
    let base: URL
    
    @MainActor
    init(base: URL, cookies: HTTPCookieStorage = HTTPCookieStorage.shared) async {
        self.base = base
        self.view = await AsyncWKWebView(cookies: cookies)
        super.init()
    }
    
    func start(url: URL) async throws -> Set<URL> {
        self.queue.insert(url)
        return try await self.next()
    }
    
    fileprivate func next() async throws -> Set<URL> {
        guard !self.queue.isEmpty else { return self.pdfs }
        let url = self.queue.removeFirst()
        guard isVisitable(url: url) else { return try await self.next() }
        self.visited.insert(url.absoluteString)
        let html = try await self.view.html(for: url)
        let document = try SwiftSoup.parse(html)
        let anchors = try document.select("a[href]")
        for anchor in anchors {
            let href = try anchor.attr("href")
            if href.lowercased().contains(".pdf"), let url = normalize(href: href) {
                self.pdfs.insert(url)
            } else if let url = URL(string: href)?.clean(),
                      url.host == self.base.host(),
                      !self.visited.contains(href) {
                self.queue.insert(url)
            }
        }
        return try await self.next()
    }
    
    private func isVisitable(url: URL) -> Bool {
        let exclusionPaths: Set<String> = [
            "/dcu/web/user/logout"
        ]
        return !self.visited.contains(url.absoluteString) &&
        !exclusionPaths.contains(url.path()) &&
        url.lastPathComponent.hasPrefix("ems-og")
    }
    
    private func normalize(href: String) -> URL? {
        guard let url = URL(string: href) else { return nil }
        if url.host() == nil  {
            return URL(string: href, relativeTo: self.base)
        } else {
            return url
        }
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
    func html(for url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation {
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
