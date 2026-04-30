//
//  Migrations.swift
//  ogp
//
//  Created by Alex Young on 4/30/26.
//

import GRDB

func createMigrator() -> DatabaseMigrator {
    var migrator = DatabaseMigrator()
    migrator.registerMigration("createDocument") { db in
        try db.create(table: "document") { table in
            table.column("id", .text).primaryKey().notNull()
            table.column("remotePath", .text).unique(onConflict: .fail).notNull()
            table.column("fileName", .text).unique(onConflict: .fail).notNull()
            table.column("createdAt", .datetime).notNull()
            table.column("updatedAt", .datetime).notNull()
        }
        try db.create(
            index: "idx_document_remotePath",
            on: "document",
            columns: ["remotePath"]
        )
    }
    return migrator
}
