//
//  TFLiteTool.swift
//  FaceAnimation_Pytorch_CoreML
//
//  Created by zhangerbing on 2021/11/8.
//

import Foundation
import RxSwift

enum TFError: Error, LocalizedError {
    case modelFailure
    case pixelBufferFailure
    case faceDetectFailure
    case imageFailure
    
    var errorDescription: String? {
        switch self {
        case .modelFailure: return "模型创建失败"
        case .pixelBufferFailure: return "转pixelbuffer失败"
        case .faceDetectFailure: return "人脸检测失败"
        case .imageFailure: return "转image失败"
        }
    }
}

final class TFLiteTool {
    private var stdFace: [[Int]]!
    private(set) var fusion_mask: [[[Float]]]!
    
    init() {
        // 初始化需要的数据
        let stdFace_name = "male_std-landmarks"
        stdFace = FileUtils.load(name: stdFace_name, type: "json") as? [[Int]]
        
        let fusion_mask_name = "fusion_mask"
        fusion_mask = (FileUtils.load(name: fusion_mask_name, type: "json") as? [[[NSNumber]]])?.compactMap({ $0.compactMap { $0.compactMap { $0.floatValue } } })
    }
}

extension TFLiteTool {
    func detectFace(image: UIImage) -> Observable<UIImage> {
        return Observable.create { observer in
            
            let disposables = Disposables.create()
            
            guard let faceDetector = FaceDetector(model: .faceDetector), let faceKpDetector = FaceKeyPointDetector(model: .faceKeypoint) else {
                
                observer.onError(TFError.modelFailure)
                
                return disposables
            }
            
            guard let pixelBuffer = image.pixelBuffer() else {
                observer.onError(TFError.pixelBufferFailure)
                return disposables
            }

            let sourceImageSize = image.size
            // 1. 模型返回处理过的元组数据([4420, 2], [4420, 4])
            let face_result = faceDetector.runModel(onFrame: pixelBuffer) as! (configdences: [[Float]], boxes: [[Float]])
            let confidences = face_result.configdences
            let boxes = face_result.boxes
            
            // 2. 选出人脸预测框
            let faceDetectResult = self.predict_box(width: sourceImageSize.width, height: sourceImageSize.height, confidences: confidences, boxes: boxes)
            
            guard faceDetectResult.boxes.count > 0 else {
                observer.onError(TFError.faceDetectFailure)
                return disposables
            }
            // MARK: - 人脸对齐
            print("目前只支持1张人脸，默认取检测到的第一张人脸")
            
            let box = faceDetectResult.boxes[0]
            
            // 1. 进行人脸关键点检测
            guard let face = image.crop(to: box) else {
                observer.onError(TFError.imageFailure)
                return disposables
            }
            guard let faceBuffer = face.pixelBuffer() else {
                observer.onError(TFError.pixelBufferFailure)
                return disposables
            }
            let points = faceKpDetector.runModel(onFrame: faceBuffer) as! [Float]
            let landmark = self.reformLandmarks(with: points, box: box, source_image_size: sourceImageSize)
            
            // 2. 进行人脸对齐
            let alignedFace0 = OpenCVWrapper.shared().alignFace(image,
                                                                from: landmark as [Any],
                                                                to: self.stdFace!,
                                                                fromRow: Int32(landmark.count),
                                                                fromCol: Int32(landmark[0].count),
                                                                toRow: Int32(self.stdFace.count),
                                                                toCol: Int32(self.stdFace[0].count),
                                                                size: CGSize(width: 256, height: 256))
            observer.onNext(alignedFace0)
            observer.onCompleted()
            
            return disposables
        }
    }
}

extension TFLiteTool {
    @discardableResult
    func predict_box(width: CGFloat, height: CGFloat, confidences: [[Float]], boxes: [[Float]], prob_threshold: Float = 0.9 , iou_threshold: Float = 0.5, top_k: Int = -1) -> (confidences: [Float], boxes: [[Float]]) {
        // 取出confidence大于prob_threshold的值，以对应的box
        var subBox = [[Float]]()
        var probs = [Float]()
        for (index, confidence) in confidences.enumerated() {
            if confidence[1] > prob_threshold {
                probs.append(confidence[1])
                subBox.append(boxes[index])
            }
        }
        
        guard probs.count > 0 else { return ([], []) }
        
        // 进行非极大值抑制，选出分数最高的框
        let nms_result = FaceUtils.hard_nms(scores: probs, boxes: subBox)
        
        // 计算出框框在原图中的位置
        let probs_box = nms_result.boxes.map { box in
            box.enumerated().map { boxitem in
                boxitem.offset % 2 == 0 ? boxitem.element * Float(width) : boxitem.element * Float(height)
            }
        }
        
        return (nms_result.confidence, probs_box)
    }
    
    func reformLandmarks(with points: [Float], box: [Float], source_image_size: CGSize) -> [[Int]] {
        let w = source_image_size.width
        let h = source_image_size.height
        
        let face_start_ij = (box[1], box[0])
        let face_h = box[3] - box[1]
        let face_w = box[2] - box[0]
        
        // points 前一半都是坐标x，后一半都是坐标y
        let middle = points.count / 2
        let x = Array(points[..<middle]).map { Int($0 / 96.0 * face_h + face_start_ij.0) }.clamp(to: 0...(Int(h)-2))
        let y = Array(points[middle...]).map { Int($0 / 96.0 * face_w + face_start_ij.1) }.clamp(to: 0...(Int(w)-2))
        
        let zipArray = Array(zip(y, x)).map { [$0.0, $0.1] }
        return zipArray
    }
}
