//
//  RootView.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftData
import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var authentication: AuthenticationService
    @StateObject var model: RootViewModel

    private let scrim: some View = Color.black.opacity(0.2).ignoresSafeArea()
    private var content: some View {
        TabView {
            DocumentListView(repo: self.model.repo)
                .tabItem {
                    Label("Documents", systemImage: "tray.full")
                }
            SettingsView(model: model)
                .environmentObject(authentication)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }

    init(auth: AuthenticationService) {
        _model = StateObject(wrappedValue: RootViewModel(auth: auth))
    }

    var body: some View {
        ZStack {
//            AuthenticationView()
//                .environmentObject(authentication)
//                .frame(width: .zero, height: .zero)
            switch model.state {
            case .uninitialized:
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
            case .indexing(let progress):
                content
                scrim
                ProgressCard(label: "Indexing PDFs", value: progress)
            case .crawling(let progress):
                content
                scrim
                ProgressCard(label: "Finding PDFs", value: progress)
            case .downloading(let progress):
                content
                scrim
                ProgressCard(label: "Downloading PDFs", value: progress)
            case .idle:
                content
            case .error(let error):
                content
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
        .sheet(item: $authentication.targetURL,
            onDismiss: {},
            content: { url in
                AuthenticationView(url: url)
                    .environmentObject(authentication)
                    #if os(macOS)
                    .frame(minWidth: 400, minHeight: 700)
                    #endif
            }
        )
    }
}

private struct AuthenticationButton: View {

    @Binding var toggle: Bool
    var body: some View {
        Button("Refresh Cookies") { toggle = true }
    }
}

private struct ProgressCard: View {
    
    let label: String
    let value: Float
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(label)
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle())
        }.modifier(ListCardStyle())
    }
}

private struct SettingsView: View {
    
    @EnvironmentObject var auth: AuthenticationService
    @ObservedObject var model: RootViewModel
    var body: some View {
        NavigationStack {
            List {
                Button("Sync New PDFs") {
                    Task { await model.crawl() }
                }
                Button("Refresh PDFs") {
                    Task { await model.sync() }
                }
                Button("Index PDFs") {
                    Task { await model.index() }
                }
                Button("Refresh Cookies") {
                    Task { try await auth.authenticate() }
                }
                Button("Logout") {
                    Task { try await auth.logout() }
                }
            }
            .navigationTitle("Settings")
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
