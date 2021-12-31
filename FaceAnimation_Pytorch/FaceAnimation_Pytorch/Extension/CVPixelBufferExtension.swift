//
//  CVPixelBufferExtension.swift
//  CatsAndDog
//
//  Created by zhangerbing on 2021/6/3.
//

import Foundation
import Accelerate
import RxSwift

extension CVPixelBuffer {
    func centerThumbnail(of size: CGSize) -> CVPixelBuffer? {
        let imageWidth = CVPixelBufferGetWidth(self)
        let imageHeight = CVPixelBufferGetHeight(self)
        let pixelBufferType = CVPixelBufferGetPixelFormatType(self)
        
        assert(pixelBufferType == kCVPixelFormatType_32BGRA)
        
        let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)
        let imageChannels = 4
        
        let thumbnailSize = min(imageWidth, imageHeight)
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        
        var originX = 0
        var originY = 0
        
        if imageWidth > imageHeight {
            originX = (imageWidth - imageHeight) / 2
        } else {
            originY = (imageHeight - imageWidth) / 2
        }
        
        // Finds the biggest square in the pixel buffer and advances rows based on it.
        guard let inputBaseAddress = CVPixelBufferGetBaseAddress(self)?.advanced(by: originY * inputImageRowBytes + originX * imageChannels) else { return nil }
        
        // Gets vImage Buffer from input image
        var inputVImageBuffer = vImage_Buffer(data: inputBaseAddress, height: UInt(thumbnailSize), width: UInt(thumbnailSize), rowBytes: inputImageRowBytes)
        
        let thumbnailRowBytes = Int(size.width) * imageChannels
        guard let thumbnailBytes = malloc(Int(size.height) * thumbnailSize) else { return nil }
        
        // Allocates a vImage buffer for thumbnail image.
        var thumbnailVimageBuffer = vImage_Buffer(data: thumbnailBytes, height: UInt(size.width), width: UInt(size.height), rowBytes: thumbnailRowBytes)
        
        // Performs the scale operation on iput image buffer and stores it in thumbnail image buffer.
        let scaleError = vImageScale_ARGB8888(&inputVImageBuffer, &thumbnailVimageBuffer, nil, vImage_Flags(0))
        
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        
        guard scaleError == kvImageNoError else {
            return nil
        }
        
        let releaseCallBack: CVPixelBufferReleaseBytesCallback = { mutablePointer, pointer in
            if let pointer = pointer {
                free(UnsafeMutableRawPointer(mutating: pointer))
            }
        }
        
        var thumbnailPixelBuffer: CVPixelBuffer?
        
        // Converts the thumbnail vImage buffer to CVPixelBuffer
        let conversionStatus = CVPixelBufferCreateWithBytes(nil, Int(size.width), Int(size.height), pixelBufferType, thumbnailBytes, thumbnailRowBytes, releaseCallBack, nil, nil, &thumbnailPixelBuffer)
        
        guard conversionStatus == kCVReturnSuccess else {
            free(thumbnailBytes)
            return nil
        }
        
        return thumbnailPixelBuffer
    }
    
    func resize(to size: CGSize) -> CVPixelBuffer? {
        let imageWidth = CVPixelBufferGetWidth(self)
        let imageHeight = CVPixelBufferGetHeight(self)
        let pixelBufferType = CVPixelBufferGetPixelFormatType(self)
        
        assert(pixelBufferType == kCVPixelFormatType_32BGRA)
        
        let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)
        let imageChannels = 4
        
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        
        defer { CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0)) }
        
        // Finds the biggest square in the pixel buffer and advances rows based on it.
        guard let inputBaseAddress = CVPixelBufferGetBaseAddress(self) else { return nil }
        
        // Gets vImage Buffer from input image
        var inputVImageBuffer = vImage_Buffer(data: inputBaseAddress, height: vImagePixelCount(imageHeight), width: vImagePixelCount(imageWidth), rowBytes: inputImageRowBytes)
        
        let thumbnailRowBytes = Int(size.width) * imageChannels
        guard let thumbnailBytes = malloc(Int(size.height) * thumbnailRowBytes) else { return nil }
        
        // Allocates a vImage buffer for thumbnail image.
        var thumbnailVimageBuffer = vImage_Buffer(data: thumbnailBytes, height: vImagePixelCount(size.height), width: vImagePixelCount(size.width), rowBytes: thumbnailRowBytes)
        
        // Performs the scale operation on iput image buffer and stores it in thumbnail image buffer.
        let scaleError = vImageScale_ARGB8888(&inputVImageBuffer, &thumbnailVimageBuffer, nil, vImage_Flags(0))
        
        guard scaleError == kvImageNoError else {
            return nil
        }
        
        let releaseCallBack: CVPixelBufferReleaseBytesCallback = { mutablePointer, pointer in
            if let pointer = pointer {
                free(UnsafeMutableRawPointer(mutating: pointer))
            }
        }
        
        var thumbnailPixelBuffer: CVPixelBuffer?
        
        // Converts the thumbnail vImage buffer to CVPixelBuffer
        let conversionStatus = CVPixelBufferCreateWithBytes(nil, Int(size.width), Int(size.height), pixelBufferType, thumbnailBytes, thumbnailRowBytes, releaseCallBack, nil, nil, &thumbnailPixelBuffer)
        
        guard conversionStatus == kCVReturnSuccess else {
            free(thumbnailBytes)
            return nil
        }
        
        return thumbnailPixelBuffer
    }
    
    func normalize() {
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)
    
        for y in 0..<height {
            for x in 0..<width {
                let pixel = floatBuffer[y * width + x]
                floatBuffer[y * width + x] = pixel / 255.0
            }
        }
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    func loop() {
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        print("w:\(width) h:\(height)")
        
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)
    
        for y in 0..<height {
            for x in 0..<width {
                let pixel = (floatBuffer[y * width + x])
//                    .clamp(to: 0...255.0)
//                print(Int(pixel))
                print(pixel)
            }
        }
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    }
}

extension CVPixelBuffer {
    
    var image: UIImage? {
        let ciImage = CIImage(cvPixelBuffer: self)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(self), height: CVPixelBufferGetHeight(self))) {
            let image = UIImage(cgImage: cgImage)
            return image
        }
        return nil
    }
    
    var rx_image: Observable<UIImage> {
        Observable.create { observer in
            let ciImage = CIImage(cvPixelBuffer: self)
            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(self), height: CVPixelBufferGetHeight(self))) {
                let image = UIImage(cgImage: cgImage)
                observer.onNext(image)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
