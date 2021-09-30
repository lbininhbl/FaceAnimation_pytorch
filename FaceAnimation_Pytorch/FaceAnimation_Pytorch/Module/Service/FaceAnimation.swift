//
//  FaceAnimation.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/23.
//

import UIKit

struct FaceAnimation {
    
    private var generator: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "CPU-generator-SSLW1", ofType: "ptl"),
           let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Cant't find the model file!")
        }
    }()
    
    private var kpDetector: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "kkk-kp_detector", ofType: "ptl"),
           let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Cant't find the model file!")
        }
    }()
    
    func test(image: UIImage, driving_motion_kps: [[String: Any]]) {
        let resizedImage = image.resized(to: CGSize(width: 256, height: 256))
        guard var pixelBuffer = resizedImage.normalized(type: .zero_to_one) else {
            return
        }

        let pointer = UnsafeMutableRawPointer(&pixelBuffer)

        let w = Int32(resizedImage.size.width)
        let h = Int32(resizedImage.size.height)

        var value: [Float] = []
        var jacobian: [Float] = []
        kpDetector.runKpDetect(pointer, with: Int32(w), height: Int32(h)) { values, jacobians in
            value = values.map { $0.floatValue }
            jacobian = jacobians.map { $0.floatValue }
        }

        var predictions = [[NSNumber]]()

        TimeUtil.begin("generator")
        autoreleasepool {
            let count = driving_motion_kps.count
            for (index, kp_driving) in driving_motion_kps.enumerated() {
                autoreleasepool {
                    let text = String(format: "generator,进度:%.2f%%", (Float(index) / Float(count)) * 100.0)
                    print(text)

                    let jac_arr = (kp_driving["jacobian"] as! [[[NSNumber]]]).map { $0.map { $0.map { $0.floatValue } } }
                    let jac = jac_arr.flatMap { $0.flatMap { $0 } }
                    let val_arr = (kp_driving["value"] as! [[NSNumber]]).map { $0.map { $0.floatValue } }
                    let val = val_arr.flatMap { $0 }

                    let predict = generator.runGenerator(pointer, with: w, height: h, kp_driving: ["value": value, "jacobian": jacobian], kp_source: ["value": val, "jacobian": jac])
                    predictions.append(predict)
                }
            }
        }
        TimeUtil.end("generator", log: "generator所花时间")
        
    }
}
