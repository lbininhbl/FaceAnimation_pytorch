//
//  VideoWriter.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/11/2.
//

import Foundation
import AVFoundation

struct VideoWriter {
    
    private let videoWriter: AVAssetWriter
    private let videoWriterInput: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    
    private var frameCount: Int
    private let averageFrame: Int
    private let fps: Int
    
    private let outputURL: URL
    
    init(path: String, imagesCount: Int, size: CGSize, duration: Double, fps: Int) {
        outputURL = URL(fileURLWithPath: path)
        guard let videoWriter = try? AVAssetWriter(url: outputURL, fileType: .mov) else {
            fatalError("创建AVAssetWriter失败")
        }
        
        self.videoWriter = videoWriter
        
        let videoSettings: [String : Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: size.width, AVVideoHeightKey: size.height]
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: nil)
        
        videoWriter.add(videoWriterInput)
        // start a session
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        // write some samples:
        frameCount = 0
        // 每张图片所占的时间
        let averageTime = duration / Double(imagesCount)
        // 每张图片所占的帧数
        averageFrame = Int(averageTime * Double(fps))
        
        self.fps = fps
    }
    
    mutating func append(data: CVPixelBuffer) {
        var append_ok = false
        autoreleasepool {
            var j = 0
            while !append_ok && j < 30 {
                if adaptor.assetWriterInput.isReadyForMoreMediaData {
                    print("appending \(frameCount) attemp\(j)n", frameCount, j)
                    let frameTime = CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(fps))
                    let frameSeconds = CMTimeGetSeconds(frameTime)
                    print("frameCount:\(frameCount), kRecordingFPS:\(fps), frameSeconds:\(frameSeconds)")
                    append_ok = adaptor.append(data, withPresentationTime: frameTime)
                } else {
                    print("adaptor not ready \(frameCount), \(j)")
                    Thread.sleep(forTimeInterval: 0.1)
                }
                j += 1
            }
            
            if !append_ok {
                print("error appending image \(frameCount) times \(j)")
            }
            frameCount += averageFrame
        }
    }
    
    func finish(completion: @escaping (URL) -> Void) {
        // finish the session
        videoWriterInput.markAsFinished()
        videoWriter.finishWriting {
            print("finish writing")
            completion(outputURL)
        }
    }
    
    mutating func reset() {
        frameCount = 0
    }
}
