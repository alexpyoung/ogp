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
    @Published private(set) var documents: [Document] = []
    @Published var search: String = ""
    let repo: DocumentRepository
    
    init(queue: DatabaseQueue = DatabaseManager.shared.queue, repo: DocumentRepository) {
        self.queue = queue
        self.repo = repo
        
        self.$search
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .flatMap { [weak self] search -> AnyPublisher<[Document], Never> in
                guard let self else { return Just([]).eraseToAnyPublisher() }
                return ValueObservation
                    .tracking { db in
                        if search.isEmpty {
                            return try Document
                                .order(Document.Columns.fileName.asc)
                                .fetchAll(db)
                        } else {
                            return try Document
                                .filter(Document.Columns.fileName.like("%\(search)%"))
                                .order(Document.Columns.fileName.asc)
                                .fetchAll(db)
                        }
                    }
                    .publisher(in: self.queue)
                    .replaceError(with: [])
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$documents)
    }
}
