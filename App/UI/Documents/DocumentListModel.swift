//
//  DocumentQuery.swift
//  ogp
//
//  Created by Alex Young on 4/30/26.
//

import SwiftUI
import GRDB
import Combine

struct DocumentGroup: Hashable {
    
    let section: String
    let documents: [AnnotatedDocument]
}

struct DocumentSearchResult: Hashable {
    
    let fileName: String
    let tokens: [TokenSearchResult]
    var title: String {
        return self.tokens.first?.metadata?.title ?? self.fileName
    }
}

@MainActor
final class DocumentListModel: ObservableObject {
    
    private let queue: DatabaseQueue
    private var cancellables = Set<AnyCancellable>()
    @Published private(set) var documents: [AnnotatedDocument] = []
    @Published var search: String = ""
    @Published var results: [DocumentSearchResult] = []
    let repo: DocumentRepository
    var grouped: [DocumentGroup] {
        return Dictionary(grouping: self.documents) {
            String($0.document.fileName.split(separator: "_").first ?? "")
        }
        .map { DocumentGroup(section: $0.key, documents: $0.value) }
        .sorted { $0.section < $1.section }
    }
    
    init(queue: DatabaseQueue = DatabaseManager.shared.queue, repo: DocumentRepository) {
        self.queue = queue
        self.repo = repo
        self.$search
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { search in
                Task { [weak self] in
                    try await self?.query(search)
                }
            }
            .store(in: &cancellables)
    }
    
    private func query(_ query: String) async throws {
        if search.isEmpty {
            self.documents = try await self.repo.annotatedDocuments()
            self.results = []
        } else {
            let tokens = try await self.repo.search(query: search)
            self.results = Dictionary(grouping: tokens) { $0.document.fileName }
                .map { DocumentSearchResult(fileName: $0.key, tokens: $0.value) }
                .sorted { $0.fileName < $1.fileName }
        }
    }
}
