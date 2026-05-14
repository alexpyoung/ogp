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
    
    init?(data: Data, query: String = "") {
        self.rawQuery = query
        self.debouncedQuery = query
        guard let document = PDFDocument(data: data) else {
            return nil
        }
        self.document = document
        self.$rawQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .assign(to: &$debouncedQuery)
        self.$debouncedQuery
            .sink { [weak self] in self?.match(query: $0) }
            .store(in: &cancellables)
        self.match(query: query)
    }
    private func match(query: String) {
        matches = document.findString(query, withOptions: .caseInsensitive)
        currentIndex = 0
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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(.primary)
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
