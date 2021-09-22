//
//  TimeUtils.swift
//  FaceAnimationTest
//
//  Created by zhangerbing on 2021/8/20.
//

import Foundation

extension TimeUtil.Key: ExpressibleByStringLiteral {
    typealias StringLiteralType = String
    init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension TimeUtil.Key: Hashable {
    static var displayDataLoad: Self { "displayDataLoad" }
}

class TimeUtil {
    
    struct Key: RawRepresentable {
        var rawValue: String
        init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    var launchTimeInterval: TimeInterval!
    
    static let shared = TimeUtil()
    
    private var dict: [Key: TimeInterval] = [:]
    
    private init() {}
}

extension TimeUtil {
    static func logLaunchTime() {
        shared.launchTimeInterval = CFAbsoluteTimeGetCurrent()
    }
    
    static func timeFromLaunch() -> TimeInterval {
        let currentTime = CFAbsoluteTimeGetCurrent()
        return currentTime - shared.launchTimeInterval
    }
    
    static func begin(_ key: Key) {
        shared.dict[key] = CFAbsoluteTimeGetCurrent()
    }
    
    @discardableResult
    static func end(_ key: Key, log: String? = nil) -> TimeInterval {
        assert(shared.dict[key] != nil, "必须先记录开始时间")
        let currentTime = CFAbsoluteTimeGetCurrent()
        let beginTime = shared.dict[key]!
        let diff = currentTime - beginTime
        
        if let log = log {
            debugPrint("\(log): \(diff)s")
        }
        return diff
    }
}
