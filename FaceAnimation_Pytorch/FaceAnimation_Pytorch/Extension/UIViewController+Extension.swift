//
//  UIViewController+Extension.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/23.
//

import UIKit

protocol StoryboardInitializable {
    static var storyboardIdentifier: String { get }
}

extension StoryboardInitializable where Self: UIViewController {
    static var storyboardIdentifier: String { String(describing: Self.self) }
    
    static func initFromStoryboard(name: String = "Main") -> Self {
        let storyboard = UIStoryboard(name: name, bundle: .main)
        return storyboard.instantiateViewController(identifier: storyboardIdentifier) as! Self
    }
}
