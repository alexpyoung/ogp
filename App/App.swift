//
//  ogpApp.swift
//  ogp
//
//  Created by Alex Young on 4/9/26.
//

import SwiftUI

@main
struct ogpApp: App {
    var body: some Scene {
        WindowGroup {
            ApplicationView()
        }
        .modelContainer(for: PDFModel.self)
    }
}

private struct ApplicationView: View {
    
    @Environment(\.modelContext) private var context
    var body: some View {
        ContentView(model: ViewModel(store: try! PDFStore(context: self.context)))
    }
}
