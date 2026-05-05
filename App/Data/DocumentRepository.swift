//
//  DocumentRepository.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import Foundation
import SwiftData
import GRDB

protocol FileReference {
    
    var fileName: String { get }
}

struct DocumentRepository {
   
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

    func save(tokens: [DocumentToken]) async throws {
        try await self.database.write { db in
            for token in tokens {
                try token.insert(db)
                try db.execute(
                    sql: """
                        INSERT INTO documentTokenFTS (text, tokenId)
                        VALUES (?, ?)
                    """, arguments: [token.text, token.id]
                )
            }
        }
    }
    
    func search(query: String) async throws -> [TokenSearchResult] {
        try await self.database.read {
            try TokenSearchResult.fetchAll($0, sql: """
                SELECT
                    t.id AS tokenId,
                    t.text AS text,
                    d.fileName AS documentFileName,
                    bm25(documentTokenFTS) AS score
                FROM documentTokenFTS f
                JOIN documentToken t ON t.id = f.tokenId
                JOIN document d ON d.id = t.documentId
                WHERE documentTokenFTS MATCH ?
                ORDER BY score
            """, arguments: [query])
        }
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
