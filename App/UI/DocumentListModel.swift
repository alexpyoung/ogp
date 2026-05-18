//
//  DocumentQuery.swift
//  ogp
//
//  Created by Alex Young on 4/30/26.
//

import SwiftUI
import GRDB
import Combine

@MainActor
final class DocumentListModel: ObservableObject {
    
    private let queue: DatabaseQueue
    private var cancellables = Set<AnyCancellable>()
    @Published private(set) var documents: [AnnotatedDocument] = []
    @Published var search: String = ""
    @Published var results: [(key: String, value: [TokenSearchResult])] = []
    let repo: DocumentRepository
    var grouped: [(key: String, value: [AnnotatedDocument])] {
        return Dictionary(grouping: self.documents) {
            String($0.document.fileName.split(separator: "_").first ?? "")
        }
        .sorted { $0.key < $1.key }
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
            self.results = Dictionary(grouping: tokens) { $0.fileName }
                .sorted { $0.key < $1.key }
        }
    }
}
