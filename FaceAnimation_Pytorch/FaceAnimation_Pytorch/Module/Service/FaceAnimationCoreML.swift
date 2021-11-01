//
//  FaceAnimationCoreML.swift
//  FaceAnimation_Pytorch_CoreML
//
//  Created by zhangerbing on 2021/9/29.
//

import UIKit
import RxSwift

/// RxSwift版本
struct FaceAnimation {
    
    let cmmodelTool = CMModelTool()
    
    private let bag = DisposeBag()
    
//  coreml 中的维度顺序 (channels, height, width)
    func test(image: UIImage, driving_motion_kps: [[String: Any]], duration: ((UIImage) -> Void)? = nil, completion: ((URL) -> Void)? = nil) {
        DispatchQueue.global().async {
            
            var images: [UIImage] = []
            TimeUtil.begin("total")
            
            cmmodelTool.kpDetect(image: image)
                .flatMap({ cmmodelTool.processor(image: image, driving_motion_kps: driving_motion_kps, detectResult: $0) })
                .flatMap({ $0.rx_image })
                .subscribe(onNext: { output in
                    
                    images.append(output)
                    
                    let brgImage = OpenCVWrapper.bgrImage(output)
                    
                    DispatchQueue.main.async {
                        duration?(brgImage)
                    }
                }, onCompleted: {
                    
                    TimeUtil.end("total", log: "total")
                    
                    TimeUtil.begin("move")
                    
                    makeMovie(with: images, size: image.size, fps: 15) { url in
                        TimeUtil.end("move", log: "move")
                        DispatchQueue.main.async {
                            completion?(url)
                        }
                    }
                })
                .disposed(by: bag)
        }
    }
    
    
    

}

extension UIImage {
    func swapRGB2BGR() -> UIImage {
        let ciInput = CIImage(image: self)
        let ctx = CIContext()
        let swapKernel = CIColorKernel(source:
            "kernel vec4 swapRedAndGreenAmout(__sample s) {" +
                "return s.bgra;" +
            "}"
        )
        
        let ciOutput = swapKernel?.apply(extent: ciInput!.extent, arguments: [ciInput as Any])
        let cgImage = ctx.createCGImage(ciOutput!, from: ciInput!.extent)
        let uiOutput = UIImage(cgImage: cgImage!)
        return uiOutput
    }
}


