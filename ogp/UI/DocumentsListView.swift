//
//  DocumentsListView.swift
//  ogp
//
//  Created by Alex Young on 4/15/26.
//

import PDFKit
import SwiftData
import SwiftUI

struct DocumentsListView: View {
    
    let store: PDFStore
    @Query private var pdfs: [PDFModel]
    @State private var search = ""
    var grouped: [(key: String, value: [PDFModel])] {
        let values = search.count > 0
        ? pdfs.filter { $0.fileName.contains(search) }
        : pdfs
        return Dictionary(grouping: values) { model in
            String(model.fileName.split(separator: "_").first ?? "")
        }
        .map { (key: $0.key, value: $0.value.sorted { (lhs, rhs) in
            return lhs.fileName < rhs.fileName
        }) }
        .sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.key) {
                    DocumentSection(group: $0)
                }
            }
            .searchable(text: $search)
            .navigationTitle("Documents")
            .navigationDestination(for: PDFModel.self) {
                switch store.data(for: $0) {
                case .success(let data):
                    PDFKitView(data: data)
                        .navigationTitle($0.fileName)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                case .failure(let error):
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

private struct DocumentSection: View {
    
    let group: (key: String, value: [PDFModel])
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

private struct SectionTitle: View {
    
    let text: String
    var body: some View {
        Text(text).font(.headline).fontWeight(.semibold)
    }
}
