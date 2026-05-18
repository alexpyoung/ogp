//
//  OGP+String.swift
//  ogp
//
//  Created by Alex Young on 5/15/26.
//

import Foundation

extension String {
    
    var isUppercase: Bool {
        let letters = self.filter { $0.isLetter }
        if letters.isEmpty { return false }
        return letters.allSatisfy { $0.isUppercase }
    }
    
    func titlecased() -> String {
        self
            .split(separator: " ")
            .map { String($0) }
            .map {
                acronyms.contains($0.filter { $0 != "(" && $0 != ")" })
                ? $0
                : $0.lowercased().capitalized
            }
            .joined(separator: " ")
    }
}
