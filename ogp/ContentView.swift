//
//  ContentView.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    
    @Environment(\.modelContext) private var context
    @StateObject private var model = ViewModel()
    @State private var isAuthenticating = true
    
    var body: some View {
        NavigationStack {
            switch model.state {
            case .unauthenticated:
                Button("Login") {
                    isAuthenticating = true
                }
            case .crawling:
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
            case .authenticated:
                DocumentsListView()
                .navigationTitle("Documents")
                .navigationDestination(for: PDFModel.self) { pdf in
                    if let data = try? self.model.store?.load(for: pdf.id) {
                        PDFKitView(data: data)
                    } else {
                        Text("Error")
                    }
                }
            case .error(let error):
                Text(error.localizedDescription)
            }
        }
        .task {
            if self.model.store == nil {
                self.model.store = PDFStore(context: self.context)
            }
        }
        .sheet(isPresented: $isAuthenticating) {
            WebView(url: URL(string: "https://lmsdocs.fdnycloud.org")!) {
                self.isAuthenticating = false
                self.model.didAuthenticate(using: $0)
            }
        }
    }
}
