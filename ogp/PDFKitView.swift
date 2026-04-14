//
//  PDFKitView.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let request: URLRequest

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: self.request)
                if let document = PDFDocument(data: data) {
                    pdfView.document = document
                }
            } catch {
                print("Failed to load PDF:", error)
            }
        }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
