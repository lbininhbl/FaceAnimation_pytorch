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
    let tfliteTool = TFLiteTool()
    
    private let bag = DisposeBag()
    
//  coreml 中的维度顺序 (channels, height, width)
    func test(image: UIImage, driving_motion_kps: [[String: Any]], progress: ((UIImage) -> Void)? = nil, completion: ((URL) -> Void)? = nil) {
        DispatchQueue.global().async {
            TimeUtil.begin("before video")
            
            let audioPath = Bundle.main.path(forResource: "myh-fps15", ofType: "mp3")!
            let audioUrl = URL(fileURLWithPath: audioPath)
            let duration = CompositionTool.duration(of: audioUrl)
            let path = FilePath.path(subPath: "/test1.mov", shouldClear: true)
            var videoWriter = VideoWriter(path: path, imagesCount: driving_motion_kps.count, size: image.size, duration: duration, fps: 15)
            
            tfliteTool.detectFace(image: image)
                .flatMap { cmmodelTool.kpDetect(image: $0) }
                .flatMap({ cmmodelTool.processor(image: $0.image, driving_motion_kps: driving_motion_kps, detectResult: $0.result) })
                .subscribe(onNext: { output in
                    
                    let pixel = OpenCVWrapper.shared().fusionPrediction(output, mask: tfliteTool.fusion_mask, sourceImage: image)
                    videoWriter.append(data: pixel.takeRetainedValue())
                    
                }, onCompleted: {
                    
                    TimeUtil.end("before video", log: "before video")
                    
                    videoWriter.finish { url in
                        
                        CompositionTool.merge(videoURL: url, audioURL: audioUrl) { fileUrl, error in
                            DispatchQueue.main.async {
                                if let fileUrl = fileUrl {
                                    TimeUtil.end("before video", log: "after video")
                                    completion?(fileUrl)
                                }
                            }
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


