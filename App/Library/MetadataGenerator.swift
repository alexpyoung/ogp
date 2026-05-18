//
//  MetadataGenerator.swift
//  ogp
//
//  Created by Alex Young on 5/14/26.
//

import Foundation

struct MetadataGenerator {
    
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    private static func date(from string: String) -> Date? {
        let formats = [
            "MMMM d, yyyy",
            "'DATE:' MMMM d, yyyy"
        ]
        return formats.lazy.compactMap {
            formatter.dateFormat = $0
            return formatter.date(from: string)
        }.first
    }
    
    static func title(from tokens: [String]) -> String? {
        tokens.isEmpty ? nil : tokens.joined(separator: " ")
    }
    
    static func generate(id: String, tokens: [DocumentToken]) -> DocumentMetadata? {
        var section: String?
        var subsection: String?
        var date: Date?
        var titles = [String]()
        let header = tokens.filter({ $0.pageIndex == 0 && $0.location == 0 })
        for token in header {
            let pattern = /OGP\s(\d+-\d+),*\s*(.*)$/
            if section == nil {
                if let match = token.text.firstMatch(of: pattern) {
                    if match.1.count > 0 {
                        section = String(match.1)
                    }
                    if match.2.count > 0 {
                        subsection = String(match.2)
                    }
                }
            } else if date == nil {
                date = self.date(from: token.text)
            } else {
                if token.text.isUppercase,
                   let first = token.text.first,
                   !first.isNumber {
                    titles.append(token.text)
                } else if titles.count > 0 {
                    return DocumentMetadata(
                        documentId: id,
                        section: section,
                        subsection: subsection,
                        date: date,
                        title: title(from: titles)
                    )
                }
            }
        }
        if section == nil, subsection == nil, date == nil, titles.isEmpty {
            return nil
        } else {
            return DocumentMetadata(
                documentId: id,
                section: section,
                subsection: subsection,
                date: date,
                title: title(from: titles)
            )
        }
    }
}
