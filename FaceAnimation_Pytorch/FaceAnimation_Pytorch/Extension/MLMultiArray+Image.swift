//
//  MLMultiArray+Image.swift
//  FaceAnimation_Pytorch_CoreML
//
//  Created by zhangerbing on 2021/10/27.
//

import Accelerate
import CoreML

public protocol MultiArrayType: Comparable {
    static var multiArrayDataType: MLMultiArrayDataType { get }
    static func +(lhs: Self, rhs: Self) -> Self
    static func -(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
    static func /(lhs: Self, rhs: Self) -> Self
    init(_: Int)
    var toUInt8: UInt8 { get }
}

extension Double: MultiArrayType {
    public static var multiArrayDataType: MLMultiArrayDataType { return .double }
    public var toUInt8: UInt8 { return UInt8(self) }
}

extension Float: MultiArrayType {
    public static var multiArrayDataType: MLMultiArrayDataType { return .float32 }
    public var toUInt8: UInt8 { return UInt8(self) }
}

extension Int32: MultiArrayType {
    public static var multiArrayDataType: MLMultiArrayDataType { return .int32 }
    public var toUInt8: UInt8 { return UInt8(self) }
}

extension MLMultiArray {
    
    public func cgImage(min: Double = 0,
                        max: Double = 255,
                        channel: Int? = nil,
                        axes: (Int, Int, Int)? = nil,
                        transform: Bool = false) -> CGImage? {
        switch self.dataType {
        case .double:
            return _image(min: min, max: max, channel: channel, axes: axes, transform: transform)
        case .float32:
            return _image(min: Float(min), max: Float(max), channel: channel, axes: axes, transform: transform)
        case .int32:
            return _image(min: Int32(min), max: Int32(max), channel: channel, axes: axes, transform: transform)
        @unknown default:
            fatalError("Unsupported data type \(dataType.rawValue)")
        }
    }
    
    private func _image<T: MultiArrayType>(min: T,
                                           max: T,
                                           channel: Int?,
                                           axes: (Int, Int, Int)?,
                                           transform: Bool = false) -> CGImage? {
        if let (b, w, h, c) = toRawBytes(min: min, max: max, channel: channel, axes: axes, transform: transform) {
            if c == 1 {
                return CGImage.fromByteArrayGray(b, width: w, height: h)
            } else {
                return CGImage.fromByteArrayRGBA(b, width: w, height: h)
            }
        }
        return nil
    }
    
    public func toRawBytes<T: MultiArrayType>(min: T,
                                              max: T,
                                              channel: Int? = nil,
                                              axes: (Int, Int, Int)? = nil,
                                              transform: Bool = false) -> (bytes: [UInt8], width: Int, height: Int, channels: Int)? {
        if shape.count < 2 {
            print("Cannot convert MLMultiArray of shape \(shape) to image")
            return nil
        }
        
        let channelAxis: Int
        let heightAxis: Int
        let widthAxis: Int
        
        if let axes = axes {
            channelAxis = axes.0
            heightAxis = axes.1
            widthAxis = axes.2
            
            guard channelAxis >= 0 && channelAxis < shape.count && heightAxis >= 0 && heightAxis < shape.count && widthAxis >= 0 && widthAxis < shape.count else {
                print("Invalid axes \(axes) for shape \(shape)")
                return nil
            }
        } else if shape.count == 2 {
            heightAxis = 0
            widthAxis = 1
            channelAxis = -1
        } else {
            channelAxis = 0
            heightAxis = 1
            widthAxis = 2
        }
        
        let height = self.shape[heightAxis].intValue
        let width = self.shape[widthAxis].intValue
        let yStride = self.strides[heightAxis].intValue
        let xStride = self.strides[widthAxis].intValue

        let channels: Int
        let cStride: Int
        let bytesPerPixel: Int
        let channelOffset: Int
        
        if shape.count == 2 {
            channels = 1
            cStride = 0
            bytesPerPixel = 1
            channelOffset = 0
        } else {
            let channelDim = self.shape[channelAxis].intValue
            if let channel = channel {
                if channel < 0 || channel >= channelDim {
                    print("Channel must be -1, or between 0 and \(channelDim - 1)")
                    return nil
                }
                channels = 1
                bytesPerPixel = 1
                channelOffset = channel
            } else if channelDim == 1 {
                channels = 1
                bytesPerPixel = 1
                channelOffset = 0
            } else {
                if channelDim != 3 && channelDim != 4 {
                    print("Expected channel dimension to have 1, 3, or 4 channels, got \(channelDim)")
                    return nil
                }
                channels = channelDim
                bytesPerPixel = 4
                channelOffset = 0
            }
            cStride = self.strides[channelAxis].intValue
        }
        
        let count = height * width * bytesPerPixel
        var pixels = [UInt8](repeating: 255, count: count)
        
        var ptr = UnsafeMutablePointer<T>(OpaquePointer(self.dataPointer))
        ptr = ptr.advanced(by: channelOffset * cStride)
        
        for c in 0..<channels {
            for y in 0..<height {
                for x in 0..<width {
                    var value = ptr[c * cStride + y * yStride + x * xStride]
                    if transform {
                        value = value * T(255)
                    }
                    let scaled = (value - min) * T(255) / (max - min)
                    let pixel = clamp(scaled, min: T(0), max: T(255)).toUInt8
                    pixels[(y * width + x) * bytesPerPixel + c] = pixel
                }
            }
        }
        return (pixels, width, height, channels)
    }
}

public func createCGImage(fromFloatArray features: MLMultiArray,
                          min: Float = 0,
                          max: Float = 255) -> CGImage? {
    assert(features.dataType == .float32)
//    assert(features.shape.count == 3)
    
    
    
    let ptr = UnsafeMutablePointer<Float>(OpaquePointer(features.dataPointer))
    
    
    let height = features.shape[2].intValue
    let width = features.shape[3].intValue
    let channelStride = features.strides[3].intValue
    let rowStride = features.strides[2].intValue
    let srcRowBytes = rowStride * MemoryLayout<Float>.stride
    
    var blueBuffer = vImage_Buffer(data: ptr, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: srcRowBytes)
    var greenBuffer = vImage_Buffer(data: ptr.advanced(by: channelStride), height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: srcRowBytes)
    var redBuffer = vImage_Buffer(data: ptr.advanced(by: channelStride * 2), height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: srcRowBytes)
    
    let destRowBytes = width * 4
    
    var error: vImage_Error = 0
    var pixels = [UInt8](repeating: 0, count: height * destRowBytes)
    
    pixels.withUnsafeMutableBufferPointer { ptr in
        ptr.baseAddress?.pointee *= 255
        var destBuffer = vImage_Buffer(data: ptr.baseAddress!, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: destRowBytes)
        
        error = vImageConvert_PlanarFToBGRX8888(&blueBuffer, &greenBuffer, &redBuffer, Pixel_8(255), &destBuffer, [max, max, max], [min, min, min], vImage_Flags(0))
    }
    
    if error == kvImageNoError {
        return CGImage.fromByteArrayRGBA(pixels, width: width, height: height)
    }
    return nil
}

#if canImport(UIKit)
import UIKit
import RxSwift

extension MLMultiArray {
    public func image(min: Double = 0,
                      max: Double = 255,
                      channel: Int? = nil,
                      axes: (Int, Int, Int)? = nil, transform: Bool = false) -> UIImage? {
        let cgImg = cgImage(min: min, max: max, channel: channel, axes: axes, transform: transform)
        return cgImg.map { UIImage(cgImage: $0) }
    }
    
    public func createUIImage(fromFloatArray features: MLMultiArray,
                              min: Float = 0,
                              max: Float = 255) -> UIImage? {
        let cgImg = createCGImage(fromFloatArray: features, min: min, max: max)
        return cgImg.map { UIImage(cgImage: $0) }
    }
}

extension Reactive where Base: MLMultiArray {
    
    func image(axes: (Int, Int, Int)? = nil, transform: Bool = true) -> Observable<UIImage> {
        Observable.create { observer in
            let disposes = Disposables.create()
            
            let image = base.image(axes: axes, transform: transform)!
            
            observer.onNext(image)
            observer.onCompleted()
            
            return disposes
        }
    }
}

#endif
