//
//  OGP+HTTPCookie.swift
//  ogp
//
//  Created by Alex Young on 6/24/26.
//

import Foundation

extension HTTPCookie {
    
    var isExpired: Bool {
        guard let expiresDate = self.expiresDate else {
            return false
        }
        return expiresDate < Date()
    }
}
