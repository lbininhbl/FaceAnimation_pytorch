//
//  FaceAnimationCoreML+Extension.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/11/1.
//

import UIKit

/// 正常版本
extension FaceAnimation {
    func test2(image: UIImage, driving_motion_kps: [[String: Any]], duration: ((UIImage) -> Void)? = nil, completion: ((URL) -> Void)? = nil) {
        
        DispatchQueue.global().async {
            
            var images: [UIImage] = []
            TimeUtil.begin("total")
            cmmodelTool.kpDetect(image: image) { value, jac in
                
                cmmodelTool.processor(image: image, driving_motion_kps: driving_motion_kps, detectResult: (value, jac)) { output in
                    TimeUtil.begin("ml")
//                    let res = output.image(axes: (3, 1, 2), transform: true)
                    let res = output.image
//                    let sss = OpenCVWrapper.bgrImage(res!)
                    images.append(res!)
                    TimeUtil.end("ml", log: "转图片")
                    
//                    DispatchQueue.main.async {
//                        duration?(sss)
//                    }
                } finish: {
                    
                    TimeUtil.end("total", log: "total")
                    
                    TimeUtil.begin("move")
                    makeMovie(with: images, size: image.size, fps: 15) { url in
                        TimeUtil.end("move", log: "move")
                        DispatchQueue.main.async {
                            completion?(url)
                        }
                    }
                }

            }
        }
        
    }
    
    func makeMovie(with images: [UIImage], size: CGSize, fps: Int, finish: @escaping (URL) -> Void) {
        let audioPath = Bundle.main.path(forResource: "myh-fps15", ofType: "mp3")!
        let audioUrl = URL(fileURLWithPath: audioPath)
        let duration = CompositionTool.duration(of: audioUrl)
        
        let path = FilePath.path(subPath: "/test1.mov", shouldClear: true)
        
        TimeUtil.begin("composition")
        CompositionTool.write(images: images, to: path, size: size, duration: duration, fps: fps) {
            TimeUtil.end("composition", log: "图片合成视频")
            let url = FilePath.fileURL(subPath: "/test1.mov")
        
            TimeUtil.begin("composition audio")
            CompositionTool.merge(videoURL: url, audioURL: audioUrl) { result in
                TimeUtil.end("composition audio", log: "音频合成")
                switch result {
                case .success(let fileUrl):
                    DispatchQueue.main.async {
                        finish(fileUrl)
                    }
                case .failure(_):
                    break
                }
                
            }
        }
    }
}
