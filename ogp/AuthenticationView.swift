//
//  TestWebView.swift
//  ogp
//
//  Created by Alex Young on 4/13/26.
//

import SwiftUI
import WebKit

struct AuthenticationView: UIViewRepresentable {
    
    enum Result {
        case unauthenticated
        case authenticated([HTTPCookie])
    }
    let onComplete: (Result) async -> Void

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero, configuration: .init())
        view.navigationDelegate = context.coordinator
        if let url = URL(string: "https://lmsdocs.fdnycloud.org") {
            view.load(URLRequest(url: url))
        }
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onComplete: onComplete)
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, WKNavigationDelegate {
        let onComplete: (Result) async -> Void

        init(onComplete: @escaping (Result) async -> Void) {
            self.onComplete = onComplete
        }

        func webView(_ view: WKWebView, didFinish _: WKNavigation!) {
            guard let url = view.url?.clean() else { return }
            Task {
                switch url.absoluteString {
                case "https://lmsdocs.fdnycloud.org/dcu/web/":
                    let cookies = await view.cookies()
                    await self.onComplete(.authenticated(cookies))
                case "https://lmsdocs.fdnycloud.org/dcu/web/user/login":
                    await self.onComplete(.unauthenticated)
                default: return
                }
            }
        }
    }
}
