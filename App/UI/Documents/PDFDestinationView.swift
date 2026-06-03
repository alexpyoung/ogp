//
//  PDFDestinationView.swift
//  ogp
//
//  Created by Alex Young on 6/3/26.
//

import SwiftUI

struct PDFDestinationView: View {
    
    let title: String
    let url: URL
    var search: (query: String, result: TokenSearchResult)? = nil
    @State private var isSharing: Bool = false
    var body: some View {
        switch self.url.data() {
        case .success(let data):
            PDFSearchView(model: PDFSearchModel(
                data: data,
                search: search
            )!)
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
