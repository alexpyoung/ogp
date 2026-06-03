//
//  RootView.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftData
import SwiftUI

struct RootView: View {
    
    @StateObject var model: ViewModel
    @State private var isAuthenticating = false
    @State private var error: Error?
    private var authenticationText: String {
        if case .unauthenticated = self.model.state {
            "Login"
        } else {
            "Logout"
        }
    }
    
    private let scrim: some View = Color.black.opacity(0.2).ignoresSafeArea()
    private var settings: some View {
        NavigationStack {
            List {
                Button("Sync New PDFs") {
                    Task { await self.model.crawl() }
                }
                Button("Refresh PDFs") {
                    Task { await self.model.sync() }
                }
                Button("Index PDFs") {
                    Task { await self.model.index() }
                }
                Button(authenticationText) {
                    self.isAuthenticating = true
                }
            }
            .navigationTitle("Settings")
        }
    }
    var body: some View {
        ZStack {
            AuthenticationView(url: self.model.baseURL) {
                switch $0 {
                case .authenticated(let cookies):
                    await self.model.didAuthenticate(using: cookies)
                case .unauthenticated:
                    self.isAuthenticating = true
                }
            }
            .frame(width: .zero, height: .zero)
            TabView {
                DocumentListView(model: DocumentListModel(repo: self.model.repo))
                    .tabItem {
                        Label("Documents", systemImage: "tray.full")
                    }
                self.settings.tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }
            switch model.state {
            case .uninitialized:
                scrim
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
            case .unauthenticated:
                scrim
                Button("Login") { isAuthenticating = true }
            case .indexing(let progress):
                scrim
                VStack(alignment: .center, spacing: 16) {
                    Text("Indexing PDFs")
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                }.modifier(ListCardStyle())
            case .crawling(let progress):
                scrim
                VStack(alignment: .center, spacing: 16) {
                    Text("Finding PDFs")
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                }.modifier(ListCardStyle())
            case .downloading(let progress):
                scrim
                VStack(alignment: .center, spacing: 16) {
                    Text("Downloading PDFs")
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                }.modifier(ListCardStyle())
            case .authenticated: EmptyView()
            case .error(let error):
                Spacer()
                    .frame(height: 0)
                    .alert(
                        "Error",
                        isPresented: .constant(true),
                        actions: { Button("OK") {} },
                        message: { Text(error.localizedDescription) }
                    )
            }
        }
        .sheet(isPresented: $isAuthenticating) {
            AuthenticationView(url: self.model.authenticationURL) {
                switch $0 {
                case .unauthenticated: return
                case .authenticated(let cookies):
                    self.isAuthenticating = false
                    await self.model.didAuthenticate(using: cookies)
                    await self.model.crawl()
                    await self.model.index()
                }
            }
            #if os(macOS)
            .frame(minWidth: 400, minHeight: 700)
            #endif
        }
    }
}

private struct ListCardStyle: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            #if os(iOS)
            .background(Color(.secondarySystemBackground))
            #elseif os(macOS)
            .background(Color(NSColor.controlBackgroundColor))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 18)
    }
}
