//
//  Path.swift
//  VideoComposition
//
//  Created by zhangerbing on 2021/4/21.
//

import Foundation

struct FilePath {
    static func path(directory: FileManager.SearchPathDirectory = .documentDirectory,
                     domainMask: FileManager.SearchPathDomainMask = .userDomainMask,
                     subPath: String,
                     shouldClear: Bool = false) -> String {
        let path = NSSearchPathForDirectoriesInDomains(directory, domainMask, true)[0] + subPath
        if shouldClear, FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
        return path
    }
    
    static func fileURL(directory: FileManager.SearchPathDirectory = .documentDirectory,
                    domainMask: FileManager.SearchPathDomainMask = .userDomainMask,
                    subPath: String,
                    shouldClear: Bool = false) -> URL {
        let path = FilePath.path(directory: directory, domainMask: domainMask, subPath: subPath, shouldClear: shouldClear)
        let url = URL(fileURLWithPath: path)
        return url
    }
}
