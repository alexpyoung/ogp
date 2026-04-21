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
    private let loader: HTMLProvider
    private var enqueuedCount: Float = 0
    @Published private(set) var progress: Float = 0
    let base: URL
    let exclusions: [URL]
    
    init(base: URL, exclusions: [URL], loader: HTMLProvider) {
        self.base = base
        self.exclusions = exclusions
        self.loader = loader
        super.init()
    }
    
    func start(url: URL) async throws -> Set<String> {
        await self.enqueue(url: url.absoluteString)
        return try await self.next([])
    }
    
    private func enqueue(url: String) async {
        self.queue.insert(url)
        self.enqueuedCount += 1
        await MainActor.run {
            let total = self.enqueuedCount + Float(self.queue.count)
            let progress = self.enqueuedCount / total
            if progress > self.progress { self.progress = progress }
        }
    }
    
    private func next(_ results: Set<String>) async throws -> Set<String> {
        if self.queue.isEmpty {
            return results
        }
        var results = results
        let url = self.queue.removeFirst()
        guard self.isVisitable(url: url) else {
            return try await self.next(results)
        }
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
            } else if let url = URL(string: href)?.normalize()?.absoluteString {
                await self.enqueue(url: url)
            }
        }
        return try await self.next(results)
    }
    
    private func isVisitable(url: String) -> Bool {
        guard let url = URL(string: url) else {
            return false
        }
        if self.visited.contains(url.absoluteString) {
            return false
        } else if self.exclusions.contains(where: { $0.path == url.path }) {
            return false
        } else {
            return url.host == self.base.host && url.lastPathComponent.hasPrefix("ems-og")
        }
    }
}
