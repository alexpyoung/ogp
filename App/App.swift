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
    
    @Environment(\.modelContext) private var context
    var body: some View {
        ContentView(model: ViewModel(store: try! PDFStore(context: self.context)))
    }
}
