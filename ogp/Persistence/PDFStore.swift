//
//  PDFStore.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import Foundation
import SwiftData

@MainActor
final class PDFStore {
    
    private let baseUrl: URL
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        self.baseUrl = appSupport.appendingPathComponent("PDFs", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: self.baseUrl,
            withIntermediateDirectories: true
        )
    }
    
    func load(for id: UUID) throws -> Data? {
        let descriptor = FetchDescriptor<PDFModel>(predicate: #Predicate { $0.id == id })
        guard let model = try self.context.fetch(descriptor).first else { return nil }
        let url = self.baseUrl.appendingPathComponent(model.filename)
        return try Data(contentsOf: url)
    }
    
    func save(filename: String, data: Data, remoteUrl: URL) throws -> PDFModel {
        let url = self.baseUrl.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        let model = PDFModel(url: remoteUrl, filename: filename)
        self.context.insert(model)
        try context.save()
        return model
    }
}
