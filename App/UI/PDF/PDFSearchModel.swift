//
//  PDFSearchModel.swift
//  ogp
//
//  Created by Alex Young on 6/3/26.
//

import Combine
import PDFKit

final class PDFSearchModel: ObservableObject {
    
    let document: PDFDocument
    @Published var query: String
    @Published var selection: PDFSelection? = nil
    @Published private(set) var matches: [PDFSelection] = []
    @Published private var currentIndex: Int = 0 {
        didSet {
            selection = matches.indices.contains(currentIndex)
                ? matches[currentIndex]
                : nil
        }
    }
    private var cancellables = Set<AnyCancellable>()
    var resultsLabel: String {
        return matches.count > 0
            ? "\(currentIndex + 1)/\(matches.count)"
            : "0/0"
    }
    private let token: TokenSearchResult?
    
    init?(data: Data, search: (query: String, result: TokenSearchResult)? = nil) {
        guard let document = PDFDocument(data: data) else {
            return nil
        }
        self.query = search?.query ?? ""
        self.document = document
        self.token = search?.result
        self.$query
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.match(query: $0) }
            .store(in: &cancellables)
    }
    
    private func index() -> Int {
        if let bounds = token?.token.bounds,
           let index = token?.token.pageIndex,
           let page = self.document.page(at: index) {
            return self.matches.index(nearest: bounds, in: page) ?? 0
        } else {
            return 0
        }
    }
    
    private func match(query: String) {
        matches = document.findString(query, withOptions: .caseInsensitive)
        currentIndex = self.index()
    }

    func next() {
        guard !matches.isEmpty else { return }
        currentIndex = (currentIndex + 1) % matches.count
    }

    func previous() {
        guard !matches.isEmpty else { return }
        currentIndex = (currentIndex - 1 + matches.count) % matches.count
    }
}

private extension Array where Element: PDFSelection {
    
    func index(nearest to: CGRect, in page: PDFPage) -> Int? {
        if let element = self
            .filter({ $0.pages.contains(page) })
            .min(by: { $0.distance(to: to, in: page) < $1.distance(to: to, in: page)})
        {
            return self.firstIndex(of: element)
        } else {
            return nil
        }
    }
}

private extension PDFSelection {
    
    func distance(to b: CGRect, in page: PDFPage) -> CGFloat {
        let a = self.bounds(for: page)
        let dx = a.midX - b.midX
        let dy = a.midY - b.midY
        return sqrt(dx * dx + dy + dy)
    }
}
