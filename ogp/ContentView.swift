//
//  ContentView.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    
    @StateObject var model: ViewModel
    @State private var isAuthenticating = false
    
    var body: some View {
        Group {
            AuthenticationView() {
                switch $0 {
                case .authenticated: return
                case .unauthenticated: self.isAuthenticating = true
                }
            }
            .frame(width: .zero, height: .zero)
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
                TabView {
                    Tab("Documents", systemImage: "tray.full") {
                        DocumentsListView(model: self.model)
                    }
                    Tab("Settings", systemImage: "gear") {
                        Text("Settings")
                    }
                }
            case .error(let error):
                Text(error.localizedDescription)
            }
        }
        .sheet(isPresented: $isAuthenticating) {
            AuthenticationView() {
                switch $0 {
                case .unauthenticated: return
                case .authenticated(let cookies):
                    self.isAuthenticating = false
                    await self.model.didAuthenticate(using: cookies)
                }
            }
        }
    }
}
