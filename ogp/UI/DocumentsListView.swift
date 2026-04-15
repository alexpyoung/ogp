//
//  DocumentsListView.swift
//  ogp
//
//  Created by Alex Young on 4/15/26.
//

import SwiftData
import SwiftUI

struct DocumentsListView: View {
    
    @Query var docs: [PDFModel]
    
    var body: some View {
        List(docs, id: \.id) { doc in
            NavigationLink(value: doc) {
                Text(doc.id.uuidString)
            }
        }
    }
}
