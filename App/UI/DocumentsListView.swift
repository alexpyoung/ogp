//
//  DocumentsListView.swift
//  ogp
//
//  Created by Alex Young on 4/15/26.
//

import GRDBQuery
import PDFKit
import SwiftUI

struct DocumentsListView: View {
    
    @State private var isSharing = false
    @EnvironmentStateObject var model: DocumentListModel
    var grouped: [(key: String, value: [Document])] {
        return Dictionary(grouping: self.model.documents) {
            String($0.fileName.split(separator: "_").first ?? "")
        }
        .sorted { $0.key < $1.key }
    }
    
    init(store: PDFStore) {
        _model = EnvironmentStateObject { _ in
            DocumentListModel(store: store)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.key) {
                    DocumentSection(group: $0)
                }
            }
            .searchable(text: $model.search)
            .navigationTitle("Documents")
            .navigationDestination(for: Document.self) { model in
                switch self.model.store.data(for: model) {
                case .success(let data):
                    PDFKitView(data: data)
                        .navigationTitle(model.fileName)
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
                            ActivityView(items: [self.model.store.fileUrl(for: model)])
                        }
                case .failure(let error):
                    Text(error.localizedDescription)
                }
            }
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

private struct SectionTitle: View {
    
    let text: String
    var body: some View {
        Text(text).font(.headline).fontWeight(.semibold)
    }
}
