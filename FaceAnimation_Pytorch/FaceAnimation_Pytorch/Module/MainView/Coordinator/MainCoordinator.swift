//
//  MainCoordinator.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/23.
//

import UIKit
import RxSwift

class MainCoordinator: BaseCoordinator<Void> {
    private let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    
    override func start() -> Observable<Void> {
        
        let viewModel = MainViewModel(faceAnimation: FaceAnimation())
        let vc = MainViewController.initFromStoryboard()
        let navc = UINavigationController(rootViewController: vc)
        navc.isNavigationBarHidden = true
        
        vc.viewModel = viewModel
        viewModel.bindModel()
        
        
        window.rootViewController = navc
        window.makeKeyAndVisible()
        
        return .never()
    }
    
}
