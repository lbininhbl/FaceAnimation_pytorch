//
//  FileUtils.swift
//  FaceAnimationTest
//
//  Created by zhangerbing on 2021/8/19.
//

import Foundation

struct FileUtils {
    
    static func load(name: String, type: String) -> Any? {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        let result = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        return result
    }
    
}
