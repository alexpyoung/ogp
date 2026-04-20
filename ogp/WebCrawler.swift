//
//  WebCrawler.swift
//  ogp
//
//  Created by Alex Young on 4/13/26.
//

import Foundation
import SwiftSoup

final class WebCrawler: NSObject, ObservableObject {
    
    private var queue: Set<String> = []
    private var visited: Set<String> = []
    private let loader: HTMLLoader
    private var enqueuedCount: Float = 0
    @Published private(set) var progress: Float = 0
    let base: URL
    
    @MainActor
    init(base: URL, cookies: HTTPCookieStorage = HTTPCookieStorage.shared) async {
        self.base = base
        self.loader = await HTMLLoader(cookies: cookies)
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
            let total = self.enqueuedCount + Float(self.queue.count)
            let progress = self.enqueuedCount / total
            if progress > self.progress { self.progress = progress }
        }
    }
    
    fileprivate func next(_ results: Set<String>) async throws -> Set<String> {
        if self.queue.isEmpty { return results }
        var results = results
        let url = self.queue.removeFirst()
        guard isVisitable(url: url) else { return try await self.next(results) }
        self.visited.insert(url)
        let html = try await self.loader.string(for: url)
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
