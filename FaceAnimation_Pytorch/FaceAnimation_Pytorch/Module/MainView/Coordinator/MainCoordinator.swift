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
        
        Observable.combineLatest(viewModel.execute, viewModel.image) { _, image in
            viewModel.faceAnimation.test(image: image, driving_motion_kps: viewModel.driving_motion_kps)
        }.subscribe().disposed(by: disposeBag)
        
        window.rootViewController = navc
        window.makeKeyAndVisible()
        
        return .never()
    }
    
}
