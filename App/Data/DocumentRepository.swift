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
    
    init(database: DatabaseManager = .shared) throws {
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
    
    func annotatedDocuments() async throws -> [AnnotatedDocument] {
        return try await self.database.read {
            return try Document
                .including(optional: Document.metadata.forKey("metadata"))
                .asRequest(of: AnnotatedDocument.self)
                .fetchAll($0)
                .sorted { (a, b) in
                    if a.metadata?.section == b.metadata?.section {
                        switch (a.metadata?.subsection, b.metadata?.subsection) {
                        case (_, nil):
                            return false
                        case (nil, .some):
                            return true
                        case (.some(let amd), .some(let bmd)):
                            return amd < bmd
                        }
                    } else {
                        switch (a.metadata?.section, b.metadata?.section) {
                        case (nil, _):
                            return false
                        case (.some, nil):
                            return true
                        case (.some(let amd), .some(let bmd)):
                            return amd < bmd
                        }
                    }
                }
        }
    }
    
    func documents() async throws -> [Document] {
        return try await self.database.read {
            return try Document
                .order(Document.Columns.fileName.asc)
                .fetchAll($0)
        }
    }
    
    func deleteAll<T: TableRecord>(of type: T.Type) async throws -> Int {
        return try await self.database.write {
            return try T.deleteAll($0)
        }
    }
    
    func save(data: Data, from remotePath: String) async throws -> Document {
        let model = try await self.model(from: remotePath)
        try data.write(to: self.fileUrl(for: model), options: .atomic)
        return model
    }
    
    func save(metadata: DocumentMetadata) async throws {
        try await self.database.write {
            try metadata.insert($0)
        }
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
    
    func fileUrl(for reference: any FileReference) -> URL {
        return self.baseUrl
            .appendingPathComponent(reference.fileName)
            .standardizedFileURL
    }
}
