//
//  FaceAnimationCoreML.swift
//  FaceAnimation_Pytorch_CoreML
//
//  Created by zhangerbing on 2021/9/29.
//

import UIKit
import RxSwift

struct FaceAnimation {
    
    private let cmmodelTool = CMModelTool()
    
    private let bag = DisposeBag()
    
    func test(image: UIImage, driving_motion_kps: [[String: Any]]) {
        cmmodelTool.kpDetect(image: image)
            .flatMap { cmmodelTool.generate(image: image, driving_motion_kps: driving_motion_kps, source: $0) }
            .subscribe(onNext: { output in
                
            })
            .disposed(by: bag)
    }
}
