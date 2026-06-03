//
//  ogpApp.swift
//  ogp
//
//  Created by Alex Young on 4/9/26.
//

import SwiftUI

@main
struct ogpApp: App {
    
    init() {
        try! DatabaseManager.shared.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            ApplicationView()
        }
    }
}

private struct ApplicationView: View {
    
    var body: some View {
        RootView(model: RootViewModel(repo: try! DocumentRepository()))
    }
}
