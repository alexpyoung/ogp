//
//  OGP+URLRequest.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import Foundation

extension URLRequest {
    
    init(url: URL, cookies: [HTTPCookie]) {
        self.init(url: url)
        let headers = HTTPCookie.requestHeaderFields(with: cookies)
        headers.forEach { key, value in
            self.setValue(value, forHTTPHeaderField: key)
        }
    }
}
