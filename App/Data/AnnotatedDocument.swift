//
//  AnnotatedDocument.swift
//  ogp
//
//  Created by Alex Young on 5/15/26.
//

import Foundation
import GRDB

struct AnnotatedDocument: FetchableRecord, Hashable {
    
    let document: Document
    let metadata: DocumentMetadata?
    
    init(row: Row) throws {
        document = try Document(row: row)
        metadata = row["metadata"]
    }
}
