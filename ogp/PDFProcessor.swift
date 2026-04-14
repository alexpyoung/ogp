//
//  PDFProcessor.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import PDFKit

struct PDFProcessor {
    
    static func text(for request: URLRequest) async throws -> String {
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let document = PDFDocument(data: data) else {
            throw NSError(domain: "PDFError", code: -1, userInfo: nil)
        }
        var text = ""
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i),
                  let pageText = page.string
            else { continue }
            text += pageText + "\n"
        }
        return text
    }
}
