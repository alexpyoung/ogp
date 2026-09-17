//
//  TestWebView.swift
//  ogp
//
//  Created by Alex Young on 4/13/26.
//

import SwiftUI
import WebKit

struct AuthenticationView {
    
    @EnvironmentObject var service: AuthenticationService
    
    final class Coordinator: NSObject, WKNavigationDelegate {
        
        let service: AuthenticationService

        init(service: AuthenticationService) {
            self.service = service
        }

        func webView(_ view: WKWebView, didFinish _: WKNavigation) {
            guard let url = view.url?.clean() else { return }
            Task {
                switch url.path {
                case let path where
                    path == "/dcu/web" ||
                    path.wholeMatch(of: #/\/dcu\/web\/user\/\d+/#) != nil:
                    let cookies = await view.cookies()
                        .filter { $0.domain == ".lmsdocs.fdnycloud.org" }
                    self.service.didSucceed(cookies: cookies)
                case "/dcu/web/user/login",
                    self.service.loginURL?.path:
                    break
                case "/oauth2/v1/authorize":
                    self.service.didFail(error: .cloudflare)
                default:
                    return
                }
            }
        }
        
        func webView(_: WKWebView, didFail: WKNavigation!, withError error: any Error) {
            self.service.didFail(error: .other(error))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(service: service)
    }
}

#if os(iOS)
extension AuthenticationView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero, configuration: .init())
        view.navigationDelegate = context.coordinator
        if let url = self.service.loginURL {
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
        if let url = self.service.loginURL {
            view.load(URLRequest(url: url))
        }
        return view
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#endif
