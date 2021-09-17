//
//  String+Extension.swift
//  FaceAnimationTest
//
//  Created by zhangerbing on 2021/8/25.
//

import Foundation

extension String {
    subscript(_ indices: ClosedRange<Int>) -> String {
        let beginIndex = index(startIndex, offsetBy: indices.lowerBound)
        let endIndex = index(startIndex, offsetBy: indices.upperBound)
        return String(self[beginIndex...endIndex])
    }
    
    subscript(_ indices: Range<Int>) -> String {
        let beginIndex = index(startIndex, offsetBy: indices.lowerBound)
        let endIndex = index(startIndex, offsetBy: indices.upperBound)
        return String(self[beginIndex..<endIndex])
    }
    
    subscript(_ indices: PartialRangeThrough<Int>) -> String {
        let endIndex = index(startIndex, offsetBy: indices.upperBound)
        return String(self[startIndex...endIndex])
    }
    
    subscript(_ indices: PartialRangeFrom<Int>) -> String {
        let beginIndex = index(startIndex, offsetBy: indices.lowerBound)
        return String(self[beginIndex..<endIndex])
    }
    
    subscript(_ indices: PartialRangeUpTo<Int>) -> String {
        let endIndex = index(startIndex, offsetBy: indices.upperBound)
        return String(self[startIndex..<endIndex])
    }
}

extension String {
    func floatValue() -> Float {
        NSString(string: self).floatValue
    }
    
    func intValue() -> Int {
        NSString(string: self).integerValue
    }
}
