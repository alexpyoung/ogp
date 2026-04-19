//
//  OGP+URLSession.swift
//  ogp
//
//  Created by Alex Young on 4/19/26.
//

import Foundation

extension URLSession {
    
    convenience init(cookies: HTTPCookieStorage) {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = cookies
        config.httpShouldSetCookies = true
        self.init(configuration: config)
    }
    
    func string(from url: URL) async throws -> String {
        let (data, _) = try await self.data(from: url)
        return String(decoding: data, as: UTF8.self)
    }
}
