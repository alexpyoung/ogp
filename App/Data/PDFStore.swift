//
//  PDFStore.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import Foundation
import SwiftData
import GRDB

struct PDFStore {
   
    private let database: DatabaseManager
    private let baseUrl: URL
    private let context: ModelContext
    
    init(context: ModelContext, database: DatabaseManager = .shared) throws {
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
        self.database = database
    }
    
    func all() async throws -> [Document] {
        return try await self.database.read {
            return try Document.fetchAll($0)
        }
    }
    
    func data(for model: Document) -> Result<Data, Error> {
        do {
            return .success(try Data(contentsOf: self.fileUrl(for: model)))
        } catch {
            return .failure(error)
        }
    }
    
    func save(data: Data, from remotePath: String) async throws -> Document {
        let model = try await self.model(from: remotePath)
        try data.write(to: self.fileUrl(for: model), options: .atomic)
        return model
    }

    func save(tokens: [DocumentToken]) {
        tokens.forEach(self.context.insert)
    }
    
    private func model(from remotePath: String) async throws -> Document {
        return try await self.database.write {
            guard let url = URL(string: remotePath) else {
                throw URLError(.badURL, userInfo: [
                    NSURLErrorFailingURLErrorKey: remotePath
                ])
            }
            let document = Document(
                remotePath: remotePath,
                fileName: url.lastPathComponent
            )
            try document.insert($0, onConflict: .ignore)
            return try Document
                .filter(Document.Columns.remotePath == remotePath)
                .fetchOne($0)!
        }
    }
    
    func fileUrl(for document: Document) -> URL {
        return self.baseUrl
            .appendingPathComponent(document.fileName)
            .standardizedFileURL
    }
}
