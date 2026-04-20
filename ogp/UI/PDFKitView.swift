//
//  PDFKitView.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        if let document = PDFDocument(data: self.data) {
            view.document = document
        }
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
