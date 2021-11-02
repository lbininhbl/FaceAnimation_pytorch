//
//  CMModelTool.swift
//  FaceAnimation_Pytorch_CoreML
//
//  Created by zhangerbing on 2021/9/29.
//

import UIKit
import CoreML
import Vision
import RxSwift
import Accelerate

class CMModelTool {
    
    lazy var kpDetector: VNCoreMLModel = {
        let model = try? VNCoreMLModel(for: kpdetector_pd149(configuration: .init()).model)
        return model!
    }()
}

extension CMModelTool {
    func kpDetect(image: UIImage) -> Observable<(value: MLMultiArray, jacobian: MLMultiArray)> {
        
        return Observable.create { observer in
            
            let dispose = Disposables.create()
            
            guard let pixelBuffer = image.pixelBuffer(with: .init(width: 256, height: 256)) else { return dispose }
            
            let request = VNCoreMLRequest(model: self.kpDetector) { request, error in
                if let error = error {
                    observer.onError(error)
                } else {
                    let results = request.results as? [VNCoreMLFeatureValueObservation]
                    
                    var predictResult: [MLMultiArray] = []
                    
                    for result in results.unsafelyUnwrapped {
                        
                        if let array = result.featureValue.multiArrayValue {
                            predictResult.append(array)
                        }
                    }
                    
                    assert(predictResult.count >= 2, "结果数量不对")
                    observer.onNext((predictResult[0], predictResult[1]))
                    observer.onCompleted()
                }
            }
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            
            do {
                try requestHandler.perform([request])
            } catch {
                debugPrint(error)
                observer.onError(error)
            }
            
            return dispose
        }
    }
    
    func processor(image: UIImage, driving_motion_kps: [[String: Any]], detectResult: (value: MLMultiArray, jacobian: MLMultiArray)) -> Observable<CVPixelBuffer>  {
        return Observable.create { observer in
            
            let dispose = Disposables.create()
            
            guard let pixelBuffer = image.pixelBuffer(with: .init(width: 256, height: 256)) else { return dispose }
            
            do {
                
                
                let configuration = MLModelConfiguration()
                configuration.computeUnits = .cpuAndGPU
//                let gen = try generator_pd149(configuration: configuration)
                let gen = try generator_pd149_maybeBGR(configuration: configuration)
                
                let processor = try kpprocessor(configuration: configuration)
                
                TimeUtil.begin("processor")
                autoreleasepool {
                    let count = driving_motion_kps.count
                    var kp_drv_init_val: MLMultiArray!
                    var kp_drv_init_jac: MLMultiArray!
                    for (index, kp_driving) in driving_motion_kps.enumerated() {
                        autoreleasepool {
                            let text = String(format: "processor,进度:%.2f%%", (Float(index) / Float(count)) * 100.0)
                            print(text)
                            
                            let jac_arr = (kp_driving["jacobian"] as! [[[NSNumber]]]).map { $0.map { $0.map { $0.floatValue } } }
                            let jac = jac_arr.flatMap { $0.flatMap { $0 } }
                            let val_arr = (kp_driving["value"] as! [[NSNumber]]).map { $0.map { $0.floatValue } }
                            let val = val_arr.flatMap { $0 }
                            
                            do {

                                let kp_drv_val = try MLMultiArray(shape: [1, 10, 2], dataType: MLMultiArrayDataType.float32)
                                let kp_drv_jac = try MLMultiArray(shape: [1, 10, 2, 2], dataType: MLMultiArrayDataType.float32)
                                
                                for (index, element) in val.enumerated() {
                                    kp_drv_val[index] = NSNumber(value: element)
                                }
                                
                                for (index, element) in jac.enumerated() {
                                    kp_drv_jac[index] = NSNumber(value: element)
                                }
                                
                                if index == 0 {
                                    kp_drv_init_val = kp_drv_val
                                    kp_drv_init_jac = kp_drv_jac
                                }
                                
                                let normal = try processor.prediction(kp_drv_val: kp_drv_val, kp_drv_jac: kp_drv_jac,
                                                                     kp_drv_init_val: kp_drv_init_val, kp_drv_init_jac: kp_drv_init_jac,
                                                                     kp_src_val: detectResult.value, kp_src_jac: detectResult.jacobian)
                                
                                let output = try gen.prediction(src_image: pixelBuffer,
                                                                kp_drv_val: normal.kp_val_norm, kp_drv_jac: normal.kp_jac_norm,
                                                                kp_src_val: detectResult.value, kp_src_jac: detectResult.jacobian)
                                
                                observer.onNext(output.pred_image)
                                
                            } catch {
                                print(error)
                                observer.onError(error)
                            }
                        }
                    }
                }
                observer.onCompleted()
                TimeUtil.end("processor", log: "processor + generator所花时间")
                
            } catch {
                print(error)
                observer.onError(error)
            }
            
            return dispose
        }
    }
    
}

private extension CMModelTool {
    func randomParam(shape: [NSNumber]) -> MLMultiArray {
        do {
            let params = try MLMultiArray(shape: shape, dataType: MLMultiArrayDataType.float32)
            
            let total = shape.reduce(1) { $0 * $1.intValue }
            
            for i in 0..<total {
                params[i] = NSNumber(value: Float.random(in: 0...1))
//                print(params[i])
            }
            
            return params
        } catch {
            print(error)
            fatalError(error.localizedDescription)
        }
    }
}
