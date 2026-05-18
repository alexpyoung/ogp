//
//  DocumentMetadata.swift
//  ogp
//
//  Created by Alex Young on 5/15/26.
//

import Foundation
import GRDB

struct DocumentMetadata: Codable, Identifiable, Hashable, FetchableRecord, PersistableRecord {
    
    var id: String = UUID().uuidString
    var createdAt = Date()
    let documentId: String
    let section: String?
    let subsection: String?
    let date: Date?
    let title: String?
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let createdAt = Column(CodingKeys.createdAt)
        static let documentId = Column(CodingKeys.documentId)
        static let section = Column(CodingKeys.section)
        static let subsection = Column(CodingKeys.subsection)
        static let date = Column(CodingKeys.date)
        static let title = Column(CodingKeys.title)
    }
}
