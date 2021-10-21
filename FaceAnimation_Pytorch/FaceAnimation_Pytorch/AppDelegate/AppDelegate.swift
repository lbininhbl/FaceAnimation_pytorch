//
//  AppDelegate.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/16.
//

import UIKit

//infix operator ???: NilCoalescingPrecedence
//
//public func ???<T>(opts: T?, defaultValue: @autoclosure () -> String) -> String {
//    switch opts {
//    case let value?: return String(describing: value)
//    case nil: return defaultValue()
//    }
//}
//
//extension Optional {
//    func map<U>(transform: (Wrapped) -> U) -> U? {
//        guard let value = self else { return nil }
//        return transform(value)
//    }
//    
//    func flatMap<U>(transform: (Wrapped) -> U?) -> U? {
//        if let value = self, let transformed = transform(value) {
//            return transformed
//        }
//        return nil
//    }
//}
//
//extension Sequence {
//    func compactMap<B>(_ transform: (Element) -> B?) -> [B] {
//        return lazy.map(transform).filter { $0 != nil }.map { $0! }
//    }
//}
//
//extension Optional: Equatable where Wrapped: Equatable {
//    static func ==(lhs: Wrapped?, rhs: Wrapped?) -> Bool {
//        switch (lhs, rhs) {
//        case (nil, nil): return true
//        case let (x?, y?): return x == y
//        case (_?, nil), (nil, _?): return false
//        }
//    }
//}
//
//infix operator !!
//
//func !!<T>(wrapped: T?, falureText: @autoclosure () -> String) -> T {
//    if let x = wrapped { return x }
//    fatalError(falureText())
//}
//
//infix operator !?
//
//func !?<T: ExpressibleByIntegerLiteral>(wrapped: T?, failureText: @autoclosure () -> String) -> T {
//    assert(wrapped != nil, failureText())
//    return wrapped ?? 0
//}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

