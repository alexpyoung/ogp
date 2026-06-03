//
//  DocumentListView.swift
//  ogp
//
//  Created by Alex Young on 4/15/26.
//

import Foundation
import GRDBQuery
import PDFKit
import SwiftUI

struct DocumentListView: View {
    
    @StateObject var model: DocumentListModel
    var body: some View {
        NavigationStack {
            List {
                if model.results.count > 0 {
                    ForEach(model.results, id: \.fileName, content: ResultView.init)
                } else {
                    ForEach(model.grouped, id: \.section, content: GroupView.init)
                }
            }
            .searchable(text: $model.search)
            .navigationTitle("OGP")
            .navigationDestination(for: DocumentGroup.self) { group in
                DocumentsDestinationView(group: group)
                    .environmentObject(self.model)
            }
            .navigationDestination(for: TokenSearchResult.self) { record in
                let url = self.model.repo.fileUrl(for: record.document)
                PDFDestinationView(
                    title: record.document.fileName,
                    url: url,
                    search: (model.search, record)
                )
            }
        }
    }
}

private struct ResultView: View {
    
    let result: DocumentSearchResult
    var body: some View {
        Section(header: Text(result.title)) {
            ForEach(result.tokens, id: \.self) { model in
                NavigationLink(value: model) {
                    Text(model.token.text)
                }
            }
        }
    }
}

private struct GroupView: View {
    
    let group: DocumentGroup
    var body: some View {
        NavigationLink(value: group) {
            Text([
                group.section,
                SectionNames[group.section]
            ].compactMap { $0 }.joined(separator: ". "))
        }
    }
}
