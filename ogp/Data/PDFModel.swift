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
    private(set) var remoteUrl: URL
    private(set) var createdAt: Date
    private(set) var updatedAt: Date
    private(set) var filename: String
    
    init(url: URL, filename: String) {
        self.id = UUID()
        self.remoteUrl = url
        self.filename = filename
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
