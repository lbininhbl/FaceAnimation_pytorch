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

class CMModelTool {
    
    lazy var kpDetector: VNCoreMLModel = {
//        let model = try? VNCoreMLModel(for: kpdetector(configuration: .init()).model)
        let model = try? VNCoreMLModel(for: kpdetector1011(configuration: .init()).model)
        return model!
    }()
    
    lazy var generator: VNCoreMLModel = {
        let model = try? VNCoreMLModel(for: generator1011(configuration: .init()).model)
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
    
    func generate(image: UIImage, driving_motion_kps: [[String: Any]], source: (value: MLMultiArray, jacobian: MLMultiArray)) -> Observable<MLMultiArray> {
        
        return Observable.create { observer in
            
            let dispose = Disposables.create()
            
            guard let pixelBuffer = image.pixelBuffer(with: .init(width: 256, height: 256)) else { return dispose }
            
            do {
                let configuration = MLModelConfiguration()
                configuration.computeUnits = .all
                let gen = try generator1011(configuration: configuration)
                
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
                            
                            do {

                                let kp_drv_val = try MLMultiArray(shape: [1, 10, 2], dataType: MLMultiArrayDataType.float32)
                                let kp_drv_jac = try MLMultiArray(shape: [1, 10, 2, 2], dataType: MLMultiArrayDataType.float32)
                                
                                for (index, element) in val.enumerated() {
                                    kp_drv_val[index] = NSNumber(value: element)
                                }
                                
                                for (index, element) in jac.enumerated() {
                                    kp_drv_jac[index] = NSNumber(value: element)
                                }
                                
                                
                                let output = try gen.prediction(image_0: pixelBuffer, kp_drv_val: kp_drv_val, kp_drv_jac: kp_drv_jac, kp_src_val: source.value, kp_src_jac: source.jacobian)
                                observer.onNext(output.var_1593)
                                
                            } catch {
                                print(error)
                                observer.onError(error)
                            }
                        }
                    }
                }
                TimeUtil.end("generator", log: "generator所花时间")
            } catch {
                print(error)
                observer.onError(error)
            }
            
            return dispose
        }
        
    }
    
    
    
    func gen_part2(image: UIImage) -> Observable<Any> {
        return Observable.create { observer in
            
            let dispose = Disposables.create()
            
            guard let pixelBuffer = image.pixelBuffer(with: .init(width: 256, height: 256)) else { return dispose }
            
            do {
                
                // 初始化加载模型
                let configuration = MLModelConfiguration()
                configuration.computeUnits = .cpuAndGPU
//                let gen = try generator_part2(configuration: configuration)
                let gen = try generator_part2_128_128(configuration: configuration)
                
                // 准备参数
                let heatmap = self.randomParam(shape: [1, 11, 1, 64, 64])
                let sparse = self.randomParam(shape: [1, 11, 64, 64, 2])
                let deformed = self.randomParam(shape: [1, 11, 3, 64, 64])
                
                TimeUtil.begin("generator_part2")
                let output = try gen.prediction(image_0: pixelBuffer, heatmap_representation: heatmap, sparse_motion: sparse, deformed_source: deformed)
                
                print(output.var_1195)
                observer.onNext(output.var_1195)
                
                TimeUtil.end("generator_part2", log: "generator_part2所花时间")
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
