//
//  PDFStore.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import Foundation
import SwiftData

@MainActor
struct PDFStore {
    
    private let baseUrl: URL
    private let context: ModelContext
    
    init(context: ModelContext) throws {
        self.context = context
        guard let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { throw POSIXError(.ENOENT) }
        self.baseUrl = support.appendingPathComponent("PDFs", isDirectory: true)
        try FileManager.default.createDirectory(
            at: self.baseUrl,
            withIntermediateDirectories: true
        )
    }
    
    func all() throws -> [PDFModel] {
        return try self.context.fetch(FetchDescriptor())
    }
    
    func data(for model: PDFModel) -> Result<Data, Error> {
        do {
            return .success(try Data(contentsOf: self.url(for: model)))
        } catch {
            return .failure(error)
        }
    }
    
    func save(data: Data, from remotePath: String) throws -> PDFModel {
        let model = try self.model(from: remotePath)
        try data.write(to: self.url(for: model), options: .atomic)
        return model
    }
    
    private func model(from remotePath: String) throws -> PDFModel {
        let descriptor = FetchDescriptor<PDFModel>(predicate: #Predicate {
            $0.remotePath == remotePath
        })
        if let model = try self.context.fetch(descriptor).first {
            model.updatedAt = Date()
            return model
        } else if let url = URL(string: remotePath) {
            let model = PDFModel(remotePath: remotePath, fileName: url.lastPathComponent)
            self.context.insert(model)
            return model
        } else {
            throw URLError(.badURL, userInfo: [
                NSURLErrorFailingURLErrorKey: remotePath
            ])
        }
    }
    
    func url(for model: PDFModel) -> URL {
        return self.baseUrl
            .appendingPathComponent(model.fileName)
            .standardizedFileURL
    }
}
