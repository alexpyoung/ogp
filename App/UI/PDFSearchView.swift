//
//  PDFSearchView.swift
//  ogp
//
//  Created by Alex Young on 5/5/26.
//

import SwiftUI
import PDFKit

struct PDFSearchView: View {
    
    @State private var rawQuery: String
    @State private var debouncedQuery: String
    @State private var selection: PDFSelection?
    @State private var matches: [PDFSelection] = []
    @State private var currentIndex: Int = 0 {
        didSet {
            if matches.indices.contains(currentIndex) {
                selection = matches[currentIndex]
            } else {
                selection = nil
            }
        }
    }
    private let document: PDFDocument
    
    init?(data: Data, search: String = "") {
        guard let document = PDFDocument(data: data) else {
            return nil
        }
        self.rawQuery = search
        self.debouncedQuery = search
        self.document = document
        self.match()
    }
    private var iterator: some View {
        Group {
            if matches.count > 0 {
                Button { previous() } label: {
                    Image(systemName: "chevron.up")
                }
                Button { next() } label: {
                    Image(systemName: "chevron.down")
                }
                Text("\(currentIndex + 1)/\(matches.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 32)
            } else {
                Text("0/0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 32)
            }
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                SearchBar(text: $rawQuery)
                if debouncedQuery.count > 0 { self.iterator }
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            Divider()
            PDFDocumentView(
                document: document,
                selection: $selection
            )
        }
        .debounced(id: rawQuery, interval: 0.3) {
            debouncedQuery = rawQuery
            match()
        }
    }
    
    private func match() {
        matches = document.findString(debouncedQuery, withOptions: .caseInsensitive)
        currentIndex = 0
    }
    private func next() {
        guard !matches.isEmpty else { return }
        currentIndex = (currentIndex + 1) % matches.count
    }
    private func previous() {
        guard !matches.isEmpty else { return }
        currentIndex = (currentIndex - 1 + matches.count) % matches.count
    }
}

private extension View {
    
    func debounced<T>(
        id value: T,
        priority: TaskPriority = .userInitiated,
        interval: TimeInterval,
        _ action: @escaping @Sendable () async -> Void
    ) -> some View where T : Equatable {
        return self.task(id: value, priority: priority) {
            let ns = UInt64(interval * 1000000000)
            try? await Task.sleep(nanoseconds: ns)
            await action()
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
