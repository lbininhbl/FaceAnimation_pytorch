//
//  Compareable+Extension.swift
//  FaceAnimationTest
//
//  Created by zhangerbing on 2021/8/19.
//

import Foundation

extension Comparable {
    func clamp(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

