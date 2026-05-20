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
    
    @State private var isSharing = false
    @StateObject var model: DocumentListModel
    
    var body: some View {
        NavigationStack {
            List {
                if model.results.count > 0 {
                    ForEach(model.results, id: \.key) {
                        ResultSection(group: $0)
                    }
                } else {
                    ForEach(model.grouped, id: \.section) { group in
                        NavigationLink(value: group) {
                            Text([
                                group.section,
                                GuideSections[group.section]
                            ].compactMap { $0 }.joined(separator: ". "))
                        }
                    }
                }
            }
            .searchable(text: $model.search)
            .navigationTitle("OGP")
            .navigationDestination(for: DocumentGroup.self) { group in
                DocumentSection(group: group)
            }
            .navigationDestination(for: TokenSearchResult.self) { record in
                let url = self.model.repo.fileUrl(for: record)
                PDFDestination(
                    title: record.fileName,
                    url: url,
                    search: model.search,
                    isSharing: $isSharing
                )
            }
            .navigationDestination(for: Document.self) { record in
                let url = self.model.repo.fileUrl(for: record)
                PDFDestination(
                    title: record.fileName,
                    url: url,
                    isSharing: $isSharing
                )
            }
        }
    }
}

private struct PDFDestination: View {
    
    let title: String
    let url: URL
    var search: String? = nil
    @Binding var isSharing: Bool
    var body: some View {
        switch self.url.data() {
        case .success(let data):
            PDFSearchView(model: PDFSearchModel(data: data, query: search ?? "")!)
                .navigationTitle(self.title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isSharing = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $isSharing) {
                    ActivityView(items: [self.url])
                }
        case .failure(let error):
            Text(error.localizedDescription)
        }
    }
}

private struct DocumentSection: View {
    
    let group: DocumentGroup
    var body: some View {
        List {
            ForEach(group.documents, id: \.self) { model in
                NavigationLink(value: model.document) {
                    DocumentItem(document: model)
                }
            }
        }
        .navigationTitle(GuideSections[group.section] ?? group.section)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct ResultSection: View {
    
    let group: (key: String, value: [TokenSearchResult])
    var body: some View {
        Section(header: Text(group.key)) {
            ForEach(group.value, id: \.self) { model in
                NavigationLink(value: model) {
                    Text(model.text)
                }
            }
        }
    }
}

private struct DocumentItem: View {
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()
    let document: AnnotatedDocument
    var body: some View {
        if let metadata = document.metadata {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    if let section = metadata.section {
                        if let subsection = metadata.subsection {
                            Text("\(section), \(subsection)")
                                .font(.caption2)
                                .foregroundStyle(Color(.systemGray))
                        } else {
                            Text(section)
                                .font(.caption2)
                                .foregroundStyle(Color(.systemGray))
                        }
                    }
                    Spacer()
                    if let date = metadata.date {
                        Text(formatter.string(from: date))
                            .font(.caption2)
                            .foregroundStyle(Color(.systemGray))
                    }
                }
                if let title = metadata.title {
                    Text(title.titlecased())
                }
            }
        } else {
            Text(document.document.fileName)
        }
    }
}

private struct SectionTitle: View {
    
    let text: String
    var body: some View {
        Text(text).font(.headline)
    }
}
