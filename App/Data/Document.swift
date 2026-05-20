//
//  Document.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import Foundation
import GRDB

struct Document: Codable, Identifiable, Hashable, FetchableRecord, PersistableRecord {
    
    let id: String
    let remotePath: String
    let fileName: String
    let createdAt: Date
    private(set) var updatedAt: Date
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let remotePath = Column(CodingKeys.remotePath)
        static let fileName = Column(CodingKeys.fileName)
        static let createdAt = Column(CodingKeys.createdAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }
    
    init(remotePath: String, fileName: String) {
        self.id = UUID().uuidString
        self.createdAt = Date()
        self.updatedAt = Date()
        self.remotePath = remotePath
        self.fileName = fileName
    }
    
    mutating func willUpdate(_: Database, columns _: Set<String>) throws {
        self.updatedAt = Date()
    }
}

extension Document: TableRecord {

    static let metadata = hasOne(
        DocumentMetadata.self,
        using: ForeignKey(["documentId"])
    )
}
