//
//  ModelDataHandler.swift
//  FaceAnimationTest
//
//  Created by zhangerbing on 2021/8/19.
//

import Foundation
import TensorFlowLite
import Accelerate

/// Information about a model file or labels file.
typealias FileInfo = (name: String, extension: String)

struct TFLiteModel {
    var name: String
    let `extension`: String = "tflite"
    
    static var faceDetector: Self { .init(name: "face_detect") }
    
    static var faceKeypoint: Self { .init(name: "facial_keypoints") }
}

enum NormalizeRange {
    case zero_to_one
    case negative_to_one
}

protocol ModelDataHandler {
    
    // MARK: - 模型参数
    var inputchannels: Int { get }
    var inputWidth: Int { get }
    var inputHeight: Int { get }
    
    // 图像归一化范围
    var normalizeRange: NormalizeRange { get }
    
    // TensorFlow Lite 模型执行解析器
    var interpreter: Interpreter { get set }
    
    init?(model: TFLiteModel, threadCount: Int)
}


extension ModelDataHandler {
    var inputchannels: Int { 3 }
    
    var normalizedRange: NormalizeRange { .negative_to_one }
    
    func rgbDataFromBuffer(_ buffer: CVPixelBuffer, byteCount: Int, needNormalize: Bool = true) -> Data? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }
        
        guard let sourceData = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let destinationChannelCount = 3
        let destinationBytesPerRow = destinationChannelCount * width
        
        var sourceBuffer = vImage_Buffer(data: sourceData, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: sourceBytesPerRow)
        
        guard let destinationData = malloc(height * destinationBytesPerRow) else { return nil }
        
        defer {
            free(destinationData)
        }
        
        var destinationBuffer = vImage_Buffer(data: destinationData, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: destinationBytesPerRow)
        
        let pixelBufferFormat = CVPixelBufferGetPixelFormatType(buffer)
        
        switch pixelBufferFormat {
        case kCVPixelFormatType_32BGRA:
            vImageConvert_BGRA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        case kCVPixelFormatType_32ARGB:
            vImageConvert_ARGB8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        case kCVPixelFormatType_32RGBA:
            vImageConvert_RGBA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        default:
            return nil
        }
        
        let byteData = Data(bytes: destinationBuffer.data, count: destinationBuffer.rowBytes * height)
        
        if !needNormalize {
            return byteData
        }
        
        let bytes = Array<UInt8>(unsafeData: byteData)!
        var floats = [Float]()
        for i in 0..<bytes.count {
//            let byte = Float(bytes[i]) / 127.0 - 1.0
            let byte = normalize(Float(bytes[i]))
            floats.append(byte)
        }
        return floats.withUnsafeBufferPointer(Data.init)
    }
    
    func normalize(_ value: Float) -> Float {
        switch normalizeRange {
        case .negative_to_one:
            return value / 127.0 - 1.0
        case .zero_to_one:
            return value / 255.0
        default:
            return value
        }
    }
}
