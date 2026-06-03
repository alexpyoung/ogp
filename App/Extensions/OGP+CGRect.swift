//
//  OGP+CGRect.swift
//  ogp
//
//  Created by Alex Young on 6/3/26.
//

import Foundation

extension CGRect {
    
    func distance(to b: CGRect) -> CGFloat {
        let dx = self.midX - b.midX
        let dy = self.midY - b.midY
        return sqrt(dx * dx + dy + dy)
    }
}

extension Array where Element == CGRect {

    func index(nearest to: CGRect) -> Int? {
        if let element = self.min(by: { $0.distance(to: to) < $1.distance(to: to) })
        {
            return self.firstIndex(of: element)
        } else {
            return nil
        }
    }
}
