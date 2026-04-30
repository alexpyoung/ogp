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
    let queue: DatabaseQueue
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
        self.queue = try DatabaseQueue(path: url.absoluteString)
    }
    
    func setup() throws {
        try self.migrator.migrate(self.queue)
    }
}
