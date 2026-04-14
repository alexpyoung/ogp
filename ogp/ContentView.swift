//
//  ContentView.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = ViewModel()
    @State private var isAuthenticating = true
    
    var body: some View {
        NavigationStack {
            switch model.state {
            case .authenticating:
                Button("Login") {
                    isAuthenticating = true
                }
            case .crawling:
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
//            case .render(let request):
//                PDFKitView(request: request)
            case .list(let items):
                List(items, id: \.self) { item in
                    NavigationLink(value: item) {
                        Text(item.url?.lastPathComponent ?? "Error")
                    }
                }
                .navigationTitle("Documents")
                .navigationDestination(for: URLRequest.self) { item in
                    PDFKitView(request: item)
                }
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
