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
    @Published var rawQuery: String
    @Published private(set) var debouncedQuery: String
    @Published var selection: PDFSelection? = nil
    @Published private(set) var matches: [PDFSelection] = []
    @Published private(set) var currentIndex: Int = 0 {
        didSet {
            if matches.indices.contains(currentIndex) {
                selection = matches[currentIndex]
            } else {
                selection = nil
            }
        }
    }
    private var cancellables = Set<AnyCancellable>()
    var resultsLabel: String {
        if matches.count > 0 {
            return "\(currentIndex + 1)/\(matches.count)"
        } else {
            return "0/0"
        }
    }
    private let token: TokenSearchResult?
    
    init?(data: Data, search: (query: String, result: TokenSearchResult)? = nil) {
        guard let document = PDFDocument(data: data) else {
            return nil
        }
        self.rawQuery = search?.query ?? ""
        self.debouncedQuery = search?.query ?? ""
        self.document = document
        self.token = search?.result
        self.$rawQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .assign(to: &$debouncedQuery)
        self.$debouncedQuery
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
        if let element = self.filter({ $0.pages.contains(page) })
            .min(by: {
                $0.bounds(for: page).distance(to: to) < $1.bounds(for: page).distance(to: to)
            }) {
                return self.firstIndex(of: element)
            } else {
                return nil
            }
    }
}

private extension CGRect {
    
    func distance(to other: CGRect) -> CGFloat {
        let dx = self.midX - other.midX
        let dy = self.midY - other.midY
        return sqrt(dx * dx + dy + dy)
    }
}
