//
//  TokenSearchResult.swift
//  ogp
//
//  Created by Alex Young on 5/5/26.
//

import Foundation
import GRDB

struct TokenSearchResult: FetchableRecord, Hashable {

    let token: DocumentToken
    let document: Document
    let metadata: DocumentMetadata?
    let score: Double

    init(row: Row) throws {
        token = try DocumentToken(row: row)
        document = try Document(row: row)
        metadata = row.hasColumn("documentId")
            ? try? DocumentMetadata(row: row)
            : nil
        score = row["score"]
    }
}
