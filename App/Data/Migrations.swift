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
    migrator.registerMigration("createDocumentToken") { db in
        try db.create(table: "documentToken") { t in
            t.column("id", .text).primaryKey().notNull()
            t.column("createdAt", .datetime).notNull()
            t.column("text", .text).notNull()
            t.column("pageIndex", .integer).notNull()
            t.column("location", .integer).notNull()
            t.column("bounds", .text).notNull()
            t.column("documentId", .text).notNull().indexed()
                .references("document", column: "id", onDelete: .cascade)
        }
    }
    migrator.registerMigration("createTokenFTS") { db in
        try db.create(virtualTable: "documentTokenFTS", using: FTS5()) { t in
            t.column("text")
            t.column("tokenId")
            t.tokenizer = FTS5TokenizerDescriptor(components: ["trigram", "remove_diacritics", "2"])
        }
    }
    migrator.registerMigration("createDocumentMetadata") { db in
        try db.create(table: "documentMetadata") { t in
            t.column("id", .text)
                .primaryKey()
            t.column("createdAt", .datetime)
                .notNull()
            t.column("documentId", .text).notNull().indexed()
                .references("document", column: "id", onDelete: .cascade)
            t.column("section", .text)
            t.column("subsection", .text)
            t.column("date", .datetime)
            t.column("title", .text)
        }
    }
    return migrator
}
