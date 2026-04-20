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
            let url = self.url(for: model.fileName)
            return .success(try Data(contentsOf: url))
        } catch {
            return .failure(error)
        }
    }
    
    func save(data: Data, from remotePath: String) throws -> PDFModel {
        let descriptor = FetchDescriptor<PDFModel>(predicate: #Predicate {
            $0.remotePath == remotePath
        })
        if let model = try self.context.fetch(descriptor).first {
            model.updatedAt = Date()
            let localUrl = self.url(for: model.fileName)
            try data.write(to: localUrl, options: .atomic)
            return model
        } else if let url = URL(string: remotePath) {
            let model = PDFModel(remotePath: remotePath, fileName: url.lastPathComponent)
            self.context.insert(model)
            let localUrl = self.url(for: model.fileName)
            try data.write(to: localUrl, options: .atomic)
            return model
        } else {
            throw URLError(.badURL, userInfo: [
                NSURLErrorFailingURLErrorKey: remotePath
            ])
        }
    }
    
    private func url(for fileName: String) -> URL {
        return self.baseUrl.appendingPathComponent(fileName).standardizedFileURL
    }
}
