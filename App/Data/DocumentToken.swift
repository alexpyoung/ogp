//
//  DocumentToken.swift
//  ogp
//
//  Created by Alex Young on 4/30/26.
//

import Foundation
import GRDB

struct DocumentToken: Codable, Identifiable, Hashable, FetchableRecord, PersistableRecord {
    
    let id: String
    let text: String
    let pageIndex: Int
    let bounds: CGRect
    let documentId: String
    let createdAt: Date
   
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let text = Column(CodingKeys.text)
        static let pageIndex = Column(CodingKeys.pageIndex)
        static let bounds = Column(CodingKeys.bounds)
        static let documentId = Column(CodingKeys.documentId)
        static let createdAt = Column(CodingKeys.createdAt)
    }
    
    init(doc: Document, pageIndex: Int, bounds: CGRect, text: String)
    {
        self.id = UUID().uuidString
        self.text = text
        self.pageIndex = pageIndex
        self.bounds = bounds
        self.documentId = doc.id
        self.createdAt = Date()
    }
}
