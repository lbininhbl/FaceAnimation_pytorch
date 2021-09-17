//
//  Array+Extension.swift
//  FaceAnimationTest
//
//  Created by zhangerbing on 2021/8/13.
//

import Foundation

extension Array {
    init?(unsafeData: Data) {
        guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
        
        #if swift(>=5.0)
        self = unsafeData.withUnsafeBytes({ .init($0.bindMemory(to: Element.self)) })
        #else
        self = unsafeData.withUnsafeBytes({
            .init(UnsafeBufferPointer<Element>(start: $0, count: unsafeData.count / MemoryLayout<Element>.stride))
        })
        #endif
    }
}


extension Array where Element: Comparable {
    func argsort() -> [Int] {
        var indices = [Int]()
        
        let sorted = self.sorted { $0 < $1 }
        
        sorted.forEach { element in
            guard let index = self.firstIndex(of: element) else { return }
            indices.append(index)
        }
        
        return indices
    }
    
    func clamp(to limits: ClosedRange<Element>) -> Self {
        map { $0.clamp(to: limits) }
    }
}

extension Array where Element == Float {
    @inlinable static func - (lhs:[Element], rhs: [Element]) -> [Element] {
        assert(lhs.count == rhs.count, "两数组个数必须相同")
        
        var array = lhs
        for (index, element) in lhs.enumerated() {
            array[index] = rhs[index] - element
        }
        
        return array
    }
    
    @inlinable static func * (lhs:[Element], rhs: [Element]) -> [Element] {
        assert(lhs.count == rhs.count, "两数组个数必须相同")
        
        var array = lhs
        for (index, element) in lhs.enumerated() {
            array[index] = rhs[index] * element
        }
        
        return array
    }
    
}

extension Array where Element == [Float] {
    @inlinable static func - (lhs:[Element], rhs: [Element]) -> [Element] {
        assert(lhs.count == rhs.count, "两数组个数必须相同")
        
        var array = lhs
        for (index, element) in lhs.enumerated() {
            array[index] = rhs[index] - element
        }
        
        return array
    }
    
    @inlinable static func * (lhs:[Element], rhs: [Element]) -> [Element] {
        assert(lhs.count == rhs.count, "两数组个数必须相同")
        
        var array = lhs
        for (index, element) in lhs.enumerated() {
            array[index] = rhs[index] * element
        }
        
        return array
    }
}


extension Array {
    /// 根据索引数组取子数组
    subscript(indices: [Int]) -> Self {
        var array = [Element]()
        indices.forEach { index in
            guard index < count else { return }
            array.append(self[index])
        }
        return array
    }
}
