//
//  DocumentToken.swift
//  ogp
//
//  Created by Alex Young on 4/30/26.
//

import Foundation
import GRDB

struct DocumentToken: Codable, Identifiable, Hashable, FetchableRecord, PersistableRecord {
    
    private(set) var id: String = UUID().uuidString
    let text: String
    let pageIndex: Int
    let location: Int
    let bounds: CGRect
    let documentId: String
    private(set) var createdAt = Date()
   
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let text = Column(CodingKeys.text)
        static let pageIndex = Column(CodingKeys.pageIndex)
        static let bounds = Column(CodingKeys.bounds)
        static let documentId = Column(CodingKeys.documentId)
        static let createdAt = Column(CodingKeys.createdAt)
    }
}
