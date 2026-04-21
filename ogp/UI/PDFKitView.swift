//
//  PDFKitView.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftUI
import PDFKit

struct PDFKitView {
    
    private let document: PDFDocument
    
    init?(data: Data) {
        guard let document = PDFDocument(data: data) else { return nil }
        self.document = document
    }
}

#if os(iOS)
extension PDFKitView: UIViewRepresentable {

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = self.document
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
#elseif os(macOS)
extension PDFKitView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = self.document
        return view
    }

    func updateNSView(_ uiView: PDFView, context: Context) {}
}
#endif
