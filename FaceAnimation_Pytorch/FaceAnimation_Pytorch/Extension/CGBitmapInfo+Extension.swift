//
//  CGBitmapInfo+Extension.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/10/28.
//

import Foundation

public enum PixelFormat {
    case abgr
    case argb
    case bgra
    case rgba
}

extension CGBitmapInfo {
    public static var byteOrder16Host: CGBitmapInfo {
        return CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) ? .byteOrder16Little : .byteOrder16Big
    }
    
    public static var byteOrder32Host: CGBitmapInfo {
        return CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) ? .byteOrder32Little : .byteOrder32Big
    }
}

extension CGBitmapInfo {
    public var pixelFormat: PixelFormat? {
        
        // AlphaFirst – the alpha channel is next to the red channel, argb and bgra are both alpha first formats.
        // AlphaLast – the alpha channel is next to the blue channel, rgba and abgr are both alpha last formats.
        // LittleEndian – blue comes before red, bgra and abgr are little endian formats.
        // Little endian ordered pixels are BGR (BGRX, XBGR, BGRA, ABGR, BGR).
        // BigEndian – red comes before blue, argb and rgba are big endian formats.
        // Big endian ordered pixels are RGB (XRGB, RGBX, ARGB, RGBA, RGB).
        
        let alphaInfo: CGImageAlphaInfo? = CGImageAlphaInfo(rawValue: rawValue & type(of: self).alphaInfoMask.rawValue)
        let alphaFirst: Bool = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst
        let alphaLast: Bool = alphaInfo == .premultipliedLast || alphaInfo == .last || alphaInfo == .noneSkipLast
        let endianLittle: Bool = self.contains(.byteOrder32Little)
        
        if alphaFirst && endianLittle {
            return .bgra
        } else if alphaFirst {
            return .argb
        } else if alphaLast && endianLittle {
            return .abgr
        } else if alphaLast {
            return .rgba
        } else {
            return nil
        }
    }
}
