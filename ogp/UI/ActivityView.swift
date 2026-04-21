//
//  ActivityView.swift
//  ogp
//
//  Created by Alex Young on 4/20/26.
//

import SwiftUI

struct ActivityView {
    let items: [Any]
}

#if os(iOS)
import UIKit
extension ActivityView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(_: UIActivityViewController, context: Context) {}
}
#elseif os(macOS)
import AppKit
extension ActivityView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let picker = NSSharingServicePicker(items: self.items)
        picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        return view
    }

    func updateNSView(_: NSView, context: Context) {}
}
#endif
