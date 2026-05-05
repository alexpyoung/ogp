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
}
