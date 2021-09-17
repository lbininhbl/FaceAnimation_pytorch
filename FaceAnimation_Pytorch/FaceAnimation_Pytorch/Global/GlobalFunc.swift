//
//  GlobalFunc.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/16.
//

import Foundation
import Accelerate

enum NormalizeType {
    case none
    case zero_to_one
    case negative_to_one
}

func RGBData(with buffer: CVPixelBuffer, normalize: NormalizeType = .zero_to_one) -> Data? {
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
    
    if normalize == .none {
        return byteData
    }
    
    let bytes = Array<UInt8>(unsafeData: byteData)!
    var floats = [Float]()
    for i in 0..<bytes.count {
        let byte = Normalize(Float(bytes[i]), type: normalize)
        floats.append(byte)
    }
    return floats.withUnsafeBufferPointer(Data.init)
}

func Normalize(_ value: Float, type: NormalizeType) -> Float {
    switch type {
    case .negative_to_one:
        return value / 127.0 - 1.0
    case .zero_to_one:
        return value / 255.0
    default:
        return value
    }
}
