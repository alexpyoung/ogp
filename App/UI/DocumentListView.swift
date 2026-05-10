//
//  DocumentListView.swift
//  ogp
//
//  Created by Alex Young on 4/15/26.
//

import GRDBQuery
import PDFKit
import SwiftUI

struct DocumentListView: View {
    
    @State private var isSharing = false
    @EnvironmentStateObject var model: DocumentListModel
    var grouped: [(key: String, value: [Document])] {
        return Dictionary(grouping: self.model.documents) {
            String($0.fileName.split(separator: "_").first ?? "")
        }
        .sorted { $0.key < $1.key }
    }
    @State private var results: [(key: String, value: [TokenSearchResult])] = []
    
    init(repo: DocumentRepository) {
        _model = EnvironmentStateObject { _ in
            DocumentListModel(repo: repo)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if results.count > 0 {
                    ForEach(results, id: \.key) {
                        ResultSection(group: $0)
                    }
                } else {
                    ForEach(grouped, id: \.key) {
                        DocumentSection(group: $0)
                    }
                }
            }
            .searchable(text: $model.search)
            .onChange(of: model.search) {
                Task {
                    let tokens = try await self.model.repo.search(query: model.search)
                    self.results = Dictionary(grouping: tokens) { $0.fileName }
                        .sorted { $0.key < $1.key }
                }
                
            }
            .navigationTitle("Documents")
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
            PDFSearchView(data: data, search: search ?? "")
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
    
    let group: (key: String, value: [Document])
    var title: String {
        if let name = GuideSections[group.key] {
            return [group.key, name].joined(separator: " - ")
        } else {
            return group.key
        }
    }
    var body: some View {
        Section(header: SectionTitle(text: title)) {
            ForEach(group.value, id: \.self) { model in
                NavigationLink(value: model) {
                    Text(model.fileName)
                }
            }
        }
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

private struct SectionTitle: View {
    
    let text: String
    var body: some View {
        Text(text).font(.headline).fontWeight(.semibold)
    }
}
