//
//  MainViewModel.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/17.
//

import Foundation
import RxSwift

class MainViewModel {
    
    // MARK: - Inputs
    let image: BehaviorSubject<UIImage>
    
    let execute: PublishSubject<String>
    
    // MARK: - Outputs
    let list: Observable<[String]>
    
    
    let faceAnimation: FaceAnimation
    
    
    private(set) var driving_motion_kps: [[String: Any]]!
    
    init(faceAnimation: FaceAnimation) {
        self.faceAnimation = faceAnimation
        
        // 初始化 fps
        let driving_kp_name = "myh-389-fps15"
        driving_motion_kps = FileUtils.load(name: driving_kp_name, type: "json") as? [[String: Any]]
        
        // 初始化图片
        let imagePath = Bundle.main.path(forResource: "male_std", ofType: "jpg")!
        let testImage = UIImage(contentsOfFile: imagePath)!
        image = BehaviorSubject<UIImage>(value: testImage)
        
        // 初始化列表
        self.list = Observable<[String]>.just(["开始执行"])
        
        self.execute = PublishSubject<String>()
    }
}
