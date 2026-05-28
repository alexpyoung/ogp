//
//  PDFSearchView.swift
//  ogp
//
//  Created by Alex Young on 5/5/26.
//

import Combine
import PDFKit
import SwiftUI

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

struct PDFSearchView: View {
    
    @StateObject var model: PDFSearchModel
    private var iterator: some View {
        Group {
            if model.matches.count > 0 {
                Button { model.previous() } label: {
                    Image(systemName: "chevron.up")
                }
                Button { model.next() } label: {
                    Image(systemName: "chevron.down")
                }
            }
            Text(model.resultsLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 32)
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                SearchBar(text: $model.rawQuery)
                if model.debouncedQuery.count > 0 { self.iterator }
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            Divider()
            PDFDocumentView(
                document: model.document,
                selection: $model.selection
            )
        }
    }
}

private struct SearchBar: View {
    
    @Binding var text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray)
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("Search")
                        .foregroundStyle(.gray)
                }
                TextField("", text: $text)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(.primary)
                    #endif
            }
            if text.count > 0 {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .frame(height: 36)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary.opacity(0.5))
        }
    }
}
