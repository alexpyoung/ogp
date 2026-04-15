//
//  PDFModel.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import Foundation
import SwiftData

@Model
class PDFModel {
    var id: UUID
    var remoteUrl: URL
    var createdAt: Date
    var updatedAt: Date
    var filename: String
    
    init(url: URL, filename: String) {
        self.id = UUID()
        self.remoteUrl = url
        self.filename = filename
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
