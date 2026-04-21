//
//  OGP+URL.swift
//  ogp
//
//  Created by Alex Young on 4/19/26.
//

import Foundation

extension URL {
    
    func clean() -> Self? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.fragment = nil
        components?.query = nil
        return components?.url
    }

    func normalize() -> Self? {
        return self.clean()?.absoluteURL.standardized
    }
}
