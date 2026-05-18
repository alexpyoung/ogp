//
//  Tokenizer.swift
//  ogp
//
//  Created by Alex Young on 4/25/26.
//

import Foundation
import PDFKit
import SwiftData

struct PDFTokenizer {
    
    let repo: DocumentRepository
    
    func tokenize(document model: Document) -> [DocumentToken] {
        let url = self.repo.fileUrl(for: model)
        guard let document = PDFDocument(url: url) else { return [] }
        var results: [DocumentToken] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index),
                  let string = page.attributedString
            else { continue }
            let range = NSRange(location: 0, length: string.length)
            string.enumerateAttributes(in: range, options: []) { _, range, _ in
                guard let selection = page.selection(for: range) else { return }
                for line in selection.selectionsByLine() {
                    guard let text = line.string?
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\u{2022}"))
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                        text.count > 0
                    else { return }
                    results.append(DocumentToken(
                        text: text,
                        pageIndex: index,
                        location: range.location,
                        bounds: line.bounds(for: page),
                        documentId: model.id
                    ))
                }
            }
        }
        return results
    }
}
