//
//  PDFDocumentView.swift
//  ogp
//
//  Created by Alex Young on 4/14/26.
//

import SwiftUI
import PDFKit

struct PDFDocumentView {
    
    let document: PDFDocument
    @Binding var selection: PDFSelection?
}

#if os(iOS)
extension PDFDocumentView: UIViewRepresentable {

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = self.document
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if let selection = self.selection {
            context.coordinator.highlight(selection: selection)
            view.setCurrentSelection(selection, animate: true)
            view.go(to: selection)
        } else {
            context.coordinator.clear()
        }
    }
    
    final class Coordinator {
        
        private var current: (PDFPage, PDFAnnotation)?
        
        func highlight(selection: PDFSelection) {
            self.clear()
            guard let line = selection.selectionsByLine().first,
                  let page = line.pages.first
            else { return }
            let annotation = PDFAnnotation(
                bounds: line.bounds(for: page),
                forType: .square,
                withProperties: nil
            )
            let color = UIColor.systemYellow.withAlphaComponent(0.4)
            annotation.color = color
            annotation.interiorColor = color
            page.addAnnotation(annotation)
            self.current = (page, annotation)
        }
        
        func clear() {
            if let (page, annotation) = self.current {
                page.removeAnnotation(annotation)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}
#elseif os(macOS)
extension PDFDocumentView: NSViewRepresentable {
    
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
