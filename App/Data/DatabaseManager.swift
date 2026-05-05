//
//  DatabaseManager.swift
//  ogp
//
//  Created by Alex Young on 4/26/26.
//

import Foundation
import GRDB

struct DatabaseManager {
    
    private var migrator: DatabaseMigrator = createMigrator()
    private(set) var queue: DatabaseQueue
    static let shared: Self = try! DatabaseManager()
    
    private init() throws {
        guard let parent = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { throw POSIXError(.ENOENT) }
        let url = parent.appendingPathComponent("database.sqlite")
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )
        var config = Configuration()
        config.prepareDatabase {
            try $0.execute(sql: "PRAGMA foreign_keys = ON")
        }
        self.queue = try DatabaseQueue(
            path: url.absoluteString,
            configuration: config
        )
    }
    
    func setup() throws {
        try self.migrator.migrate(self.queue)
    }
    
    func read<T: Sendable>(_ value: @Sendable (Database) throws -> T) async throws -> T {
        return try await self.queue.read(value)
    }
    
    func write<T: Sendable>(_ updates: @Sendable (Database) throws -> T) async throws -> T {
        return try await self.queue.write(updates)
    }
}
