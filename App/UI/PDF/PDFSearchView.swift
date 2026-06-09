//
//  PDFSearchView.swift
//  ogp
//
//  Created by Alex Young on 5/5/26.
//

import SwiftUI

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
                SearchBar(text: $model.query)
                if model.query.count > 0 { self.iterator }
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
    
    init?(data: Data, search: (query: String, result: TokenSearchResult)? = nil) {
        guard let model = PDFSearchModel(data: data, search: search) else {
            return nil
        }
        _model = StateObject(wrappedValue: model)
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
