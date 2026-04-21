//
//  PDFModel.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import Foundation
import SwiftData

@Model
final class PDFModel {
    
    private(set) var id: UUID
    private(set) var remotePath: String
    private(set) var fileName: String
    private(set) var createdAt: Date
    var updatedAt: Date

    init(remotePath: String, fileName: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.remotePath = remotePath
        self.fileName = fileName
    }
}
