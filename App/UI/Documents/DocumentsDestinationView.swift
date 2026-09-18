//
//  DocumentsDestinationView.swift
//  ogp
//
//  Created by Alex Young on 6/3/26.
//

import SwiftUI

struct DocumentsDestinationView: View {
    
    let repo: DocumentRepository
    let group: DocumentGroup
    var body: some View {
        List {
            ForEach(group.documents, id: \.self) { model in
                NavigationLink(value: model.document) {
                    DocumentLinkView(document: model)
                }
            }
        }
        .navigationTitle(SectionNames[group.section] ?? group.section)
        .navigationDestination(for: Document.self) { record in
            let url = self.repo.fileUrl(for: record)
            PDFDestinationView(
                title: record.fileName,
                url: url
            )
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct DocumentLinkView: View {
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()
    let document: AnnotatedDocument
    var body: some View {
        if let metadata = document.metadata {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    if let section = metadata.section {
                        if let subsection = metadata.subsection {
                            Text("\(section), \(subsection)")
                                .font(.caption2)
                                .foregroundStyle(Color(.systemGray))
                        } else {
                            Text(section)
                                .font(.caption2)
                                .foregroundStyle(Color(.systemGray))
                        }
                    }
                    Spacer()
                    if let date = metadata.date {
                        Text(formatter.string(from: date))
                            .font(.caption2)
                            .foregroundStyle(Color(.systemGray))
                    }
                }
                if let title = metadata.title {
                    Text(title.titlecased())
                }
            }
        } else {
            Text(document.document.fileName)
        }
    }
}
