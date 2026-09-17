//
//  ogpApp.swift
//  ogp
//
//  Created by Alex Young on 4/9/26.
//

import SwiftUI

@main
struct ogpApp: App {
    
    @StateObject var authentication = AuthenticationService()

    init() {
        try! DatabaseManager.shared.setup()
    }

    var body: some Scene {
        WindowGroup {
            RootView(auth: authentication)
                .environmentObject(authentication)
        }
    }
}
