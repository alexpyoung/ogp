//
//  AuthenticationService.swift
//  ogp
//
//  Created by Alex Young on 6/21/26.
//

import Combine
import Foundation

final class AuthenticationService: ObservableObject {
    
    enum AuthenticationError: Error {
        case unknown
        case redirection
        case cancellation
        case cloudflare
        case other(Error)
    }
    
    /// Responsible for the presentation of **AuthenticationView**
    @MainActor @Published var targetURL: URL? = nil
    let baseURL = URL(string: "https://lmsdocs.fdnycloud.org/")
    var loginURL: URL? {
        URL(string: "/dcu/web/user/login", relativeTo: self.baseURL)
    }
    var logoutURL: URL? {
        URL(string: "/dcu/web/user/logout", relativeTo: self.baseURL)
    }
    var cookies: [HTTPCookie] {
        self.storage.cookies ?? []
    }
    private var continuation: CheckedContinuation<Void, Error>?
    private let storage: HTTPCookieStorage = {
        let storage = HTTPCookieStorage.shared
        storage.cookieAcceptPolicy = .always
        return storage
    }()
    
    func session() -> URLSession {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = self.storage
        config.httpShouldSetCookies = true
        return URLSession(configuration: config)
    }
    
    @MainActor
    func authenticate() async throws {
        if self.cookies.count > 0,
           self.cookies.allSatisfy({ !$0.isExpired })
        {
            return
        }
        try await withCheckedThrowingContinuation {
            self.continuation = $0
            self.targetURL = self.loginURL
        }
    }
    
    @MainActor
    func logout() async throws {
        self.storage.removeCookies(since: .distantPast)
        try await withCheckedThrowingContinuation {
            self.continuation = $0
            self.targetURL = self.logoutURL
        }
    }
    
    @MainActor
    func didSucceed(cookies: [HTTPCookie]) {
        cookies.forEach(self.storage.setCookie)
        self.targetURL = nil
        self.continuation?.resume()
        self.continuation = nil
    }
    
    @MainActor
    func didFail(error: AuthenticationError) {
        if case .redirection = error {
            self.storage.removeCookies(since: .distantPast)
        }
        self.targetURL = nil
        self.continuation?.resume(throwing: error)
        self.continuation = nil
    }
}
