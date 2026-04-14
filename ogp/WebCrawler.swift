//
//  WebCrawler.swift
//  ogp
//
//  Created by Alex Young on 4/13/26.
//

import Foundation
import WebKit

final class WebCrawler: NSObject, ObservableObject {
    private var queue: Set<URL> = []
    private var visited: Set<String> = []
    private var pdfs: Set<String> = []
    private let exclusions: Set<String> = [
        "https://lmsdocs.fdnycloud.org/dcu/web/user/logout"
    ]
    fileprivate let baseHost = "lmsdocs.fdnycloud.org"
    private weak var view: WKWebView?
    private var onComplete: ((Set<String>) -> Void)? = nil

    func start(url: URL, view: WKWebView, onComplete: @escaping (Set<String>) -> Void) {
        self.view = view
        view.navigationDelegate = self
        self.queue.insert(url)
        self.onComplete = onComplete
        self.next()
    }
    
    fileprivate func next() {
        guard !queue.isEmpty else {
            self.onComplete?(pdfs)
            return
        }
        let url = self.queue.removeFirst()
        if visited.contains(url.absoluteString) ||
           exclusions.contains(url.absoluteString) ||
           !url.lastPathComponent.hasPrefix("ems-og")
        {
            self.next()
        } else {
            visited.insert(url.absoluteString)
            self.view?.load(URLRequest(url: url))
        }
    }
}

extension WebCrawler: WKNavigationDelegate {

    func webView(_ view: WKWebView, didFinish _: WKNavigation!) {
        let js = """
        Array.from(document.querySelectorAll('a[href]'))
          .map(a => ({
            href: new URL(a.getAttribute('href'), document.baseURI).href
          }))
        """
        view.evaluateJavaScript(js) { result, error in
            guard let anchors = result as? [[String: String]] else {
                self.next()
                return
            }
            for anchor in anchors {
                guard let href = anchor["href"] else { continue }
                if href.lowercased().contains(".pdf") {
                    self.pdfs.insert(href)
                } else if let url = URL(string: href)?.clean(),
                          url.host == self.baseHost,
                          !self.visited.contains(href) {
                    self.queue.insert(url)
                }
            }
            self.next()
        }
    }
}

extension URL {
    
    func clean() -> Self? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.fragment = nil
        components?.query = nil
        return components?.url
    }
}
