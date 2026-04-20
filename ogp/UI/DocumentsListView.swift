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
    
    var body: some View {
        NavigationStack {
            List(self.pdfs, id: \.id) { pdf in
                NavigationLink(value: pdf) {
                    Text(pdf.fileName)
                }
            }
            .navigationTitle("Documents")
            .navigationDestination(for: PDFModel.self) {
                switch store.data(for: $0) {
                case .success(let data): PDFKitView(data: data)
                case .failure(let error): Text(error.localizedDescription)
                }
            }
        }
    }
}
