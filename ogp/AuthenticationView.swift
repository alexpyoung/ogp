//
//  TestWebView.swift
//  ogp
//
//  Created by Alex Young on 4/13/26.
//

import SwiftUI
import WebKit

struct AuthenticationView: UIViewRepresentable {
    let url: URL
    let didAuthenticate: (WKWebView) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero, configuration: .init())
        view.navigationDelegate = context.coordinator
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(didAuthenticate: didAuthenticate)
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, WKNavigationDelegate {
        let didAuthenticate: (WKWebView) -> Void

        init(didAuthenticate: @escaping (WKWebView) -> Void) {
            self.didAuthenticate = didAuthenticate
        }

        func webView(_ view: WKWebView, didFinish _: WKNavigation!) {
            guard let url = view.url?.clean(),
                  url.absoluteString == "https://lmsdocs.fdnycloud.org/dcu/web/"
            else { return }
            self.didAuthenticate(view)
        }
    }
}
