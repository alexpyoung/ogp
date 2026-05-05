//
//  TokenSearchResult.swift
//  ogp
//
//  Created by Alex Young on 5/5/26.
//

import Foundation
import GRDB

struct TokenSearchResult: FetchableRecord, Hashable, FileReference {

    let tokenId: String
    let text: String
    let fileName: String
    let score: Double

    init(row: Row) throws {
        tokenId = row["tokenId"]
        text = row["text"]
        fileName = row["documentFileName"]
        score = row["score"]
    }
}
