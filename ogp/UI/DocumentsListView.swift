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
    
    let model: ViewModel
    @Query private var pdfs: [PDFModel]
    
    var body: some View {
        NavigationStack {
            List(self.pdfs, id: \.id) { pdf in
                NavigationLink(value: pdf) {
                    Text(pdf.filename)
                }
            }
            .navigationTitle("Documents")
            .navigationDestination(for: PDFModel.self) {
                if let data = try? self.model.data(for: $0) {
                    PDFKitView(data: data)
                } else {
                    Text("Error")
                }
            }
        }
    }
}
