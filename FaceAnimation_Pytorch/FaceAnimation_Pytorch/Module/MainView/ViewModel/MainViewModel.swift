//
//  MainViewModel.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/17.
//

import Foundation
import RxSwift
import RxRelay

class MainViewModel {
    
    // MARK: - Inputs
    let image: BehaviorSubject<UIImage>
    
    let execute: PublishSubject<String>
    
    // MARK: - Outputs
    let list: Observable<[String]>
    let resultImage: PublishSubject<UIImage>
    
    let video: PublishRelay<URL>
    
    private let bag = DisposeBag()
    
    let faceAnimation: FaceAnimation
    
    private(set) var driving_motion_kps: [[String: Any]]!
    
    init(faceAnimation: FaceAnimation) {
        self.faceAnimation = faceAnimation
        
        // 初始化 fps
//        let driving_kp_name = "myh-389-fps15"
        let driving_kp_name = "myh_fps_down-bd-fps15"
        driving_motion_kps = FileUtils.load(name: driving_kp_name, type: "json") as? [[String: Any]]
        
        // 初始化图片
        let imagePath = Bundle.main.path(forResource: "ctf", ofType: "jpg")!
//        let imagePath = Bundle.main.path(forResource: "laotou", ofType: "png")!
        let testImage = UIImage(contentsOfFile: imagePath)!
        image = BehaviorSubject<UIImage>(value: testImage)
        
        // 初始化列表
        self.list = Observable<[String]>.just(["开始执行-RxSwift", "重播", "保存到相册"])
        
        self.execute = PublishSubject<String>()
        
        self.resultImage = PublishSubject<UIImage>()
        
        self.video = PublishRelay<URL>()
    }
    
    func bindModel() {
        
        /// 这里也可以用sample，不过则是需要将execute作为参数。
        execute.filter { $0 == "开始执行" }.withLatestFrom(image)
            .subscribe(onNext: { image in
                self.faceAnimation.test2(image: image, driving_motion_kps: self.driving_motion_kps) { image in
                    self.resultImage.onNext(image)
                } completion: { url in
                    self.video.accept(url)
                }
            })
            .disposed(by: bag)
        
        execute.filter { $0 == "开始执行-RxSwift" }.withLatestFrom(image)
            .subscribe(onNext: { image in
                self.faceAnimation.test(image: image, driving_motion_kps: self.driving_motion_kps) { image in
                    self.resultImage.onNext(image)
                } completion: { url in
                    self.video.accept(url)
                }
            })
            .disposed(by: bag)
        
        execute.filter { $0 == "重播" }.withLatestFrom(video)
            .subscribe(onNext: { url in
                self.video.accept(url)
            })
            .disposed(by: bag)
        
        execute.filter { $0 == "保存到相册" }.withLatestFrom(video)
            .flatMap { AlbumUtils.save(url: $0) }
            .subscribe(onCompleted: {
                print("保存成功")
            })
            .disposed(by: bag)
    }
}
