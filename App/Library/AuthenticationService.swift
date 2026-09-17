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
    
    @MainActor @Published var isPresenting = false
    let baseURL = URL(string: "https://lmsdocs.fdnycloud.org/")
    var loginURL: URL? {
        URL(string: "/dcu/web/user/login", relativeTo: self.baseURL)
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
            self.isPresenting = true
        }
    }
    
    func clearCookies() {
        self.storage.removeCookies(since: .distantPast)
    }
    
    @MainActor
    func didSucceed(cookies: [HTTPCookie]) {
        cookies.forEach(self.storage.setCookie)
        self.isPresenting = false
        self.continuation?.resume()
        self.continuation = nil
    }
    
    @MainActor
    func didFail(error: AuthenticationError) {
        if case .redirection = error {
            self.storage.removeCookies(since: .distantPast)
        }
        self.continuation?.resume(throwing: error)
        self.continuation = nil
    }
}
