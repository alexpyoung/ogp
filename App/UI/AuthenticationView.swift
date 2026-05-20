//
//  TestWebView.swift
//  ogp
//
//  Created by Alex Young on 4/13/26.
//

import SwiftUI
import WebKit

struct AuthenticationView {
    
    enum Result {
        case unauthenticated
        case authenticated([HTTPCookie])
    }
    
    let url: URL?
    let onComplete: (Result) async -> Void
    
    final class Coordinator: NSObject, WKNavigationDelegate {
        
        let url: URL?
        let onComplete: (Result) async -> Void

        init(base url: URL?, onComplete: @escaping (Result) async -> Void) {
            self.url = url
            self.onComplete = onComplete
        }

        func webView(_ view: WKWebView, didFinish _: WKNavigation) {
            guard let url = view.url?.clean() else { return }
            Task {
                switch url.path {
                case "/dcu/web":
                    let cookies = await view.cookies()
                    await self.onComplete(.authenticated(cookies))
                case "/dcu/web/user/login",
                    self.url?.path:
                    await self.onComplete(.unauthenticated)
                default: return
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(base: url, onComplete: onComplete)
    }
}

#if os(iOS)
extension AuthenticationView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero, configuration: .init())
        view.navigationDelegate = context.coordinator
        if let url = self.url {
            view.load(URLRequest(url: url))
        }
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
    
}
#elseif os(macOS)
extension AuthenticationView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero, configuration: .init())
        view.navigationDelegate = context.coordinator
        if let url = self.url {
            view.load(URLRequest(url: url))
        }
        return view
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#endif
