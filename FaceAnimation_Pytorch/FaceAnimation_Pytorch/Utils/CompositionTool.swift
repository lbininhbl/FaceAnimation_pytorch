//
//  CompositionTool.swift
//  VideoComposition
//
//  Created by zhangerbing on 2021/4/8.
//

import UIKit
import AVFoundation

//typealias CompositionBlock = (_ url: URL?, _ error: Error?) -> Void

typealias CompositionBlock = (Result<URL, Error>) -> Void

func degreeToRadian(_ degree: CGFloat) -> CGFloat {
    return (.pi * degree / 180.0)
}


let exportQueue = DispatchQueue(label: "exportqueue", qos: .background, attributes: .init(rawValue: 0))

func check(export: AVAssetExportSession, on queue: DispatchQueue) {
    if export.status == .exporting || export.status == .waiting {
        let progress = export.progress
        debugPrint("正在导出", progress, Thread.current)
        
        queue.asyncAfter(deadline: .now() + .microseconds(100)) {
            check(export: export, on: queue)
        }
    }
}

struct CompositionTool {

    
    /// 合成一段视频和音频
    /// - Parameters:
    ///   - videoURL: 视频地址
    ///   - audioURL: 音频地址
    ///   - completion: 完成回调
    static func merge(videoURL: URL, audioURL: URL, completion: @escaping CompositionBlock) {
        
        // 时间起点
        let nextClistarTime = CMTime.zero
        
        // 2. 创建可变的音视频合成器
        let composition = AVMutableComposition()
        
        // 3. 采集视频
        let videoAsset = AVURLAsset(url: videoURL)
        // 视频的时间范围
        let videoTimeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
        // 4. 合成器创建一条空白的视频轨道
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        // 5. 获取视频内容轨道
        guard let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(Result.failure(NSError(domain: "data nil", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: "视频内容为空"])))
            return
        }
        
        // 6. 采集音频
        let audioAsset = AVURLAsset(url: audioURL)
        // 7. 合成器创建一条空白的音频轨道
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        // 8. 获取音频内容轨道
        guard let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first else {
            completion(Result.failure(NSError(domain: "data nil", code: -2, userInfo: [NSLocalizedFailureReasonErrorKey: "音频内容为空"])))
            return
        }
        
        // 9. 将视频、音频内容插入到相应的轨道中
        do {
            try videoTrack.insertTimeRange(videoTimeRange, of: videoAssetTrack, at: nextClistarTime)
            try audioTrack.insertTimeRange(videoTimeRange, of: audioAssetTrack, at: nextClistarTime)
        } catch {
            completion(Result.failure(error))
        }
        
        // 10. 创建导出session
        export(with: composition, completion: completion)
    }
    
    
    /// 合成一段视频和音频
    /// - Parameters:
    ///   - videoURL: 视频地址
    ///   - audioURL: 音频地址
    ///   - completion: 完成回调
//    static func merge(images: [UIImage], audioURL: URL, completion: @escaping CompositionBlock) {
//
//        // 时间起点
//        let nextClistarTime = CMTime.zero
//
//        // 2. 创建可变的音视频合成器
//        let composition = AVMutableComposition()
//
//        // 3. 采集音频
//        let audioAsset = AVURLAsset(url: audioURL)
//        // 4. 合成器创建一条空白的音频轨道
//        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
//        // 5. 获取音频内容轨道
//        guard let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first else {
//            completion(nil, NSError(domain: "data nil", code: -2, userInfo: [NSLocalizedFailureReasonErrorKey: "音频内容为空"]))
//            return
//        }
//
//        // 视频的时间范围
//        let videoTimeRange = CMTimeRange(start: .zero, duration: audioAsset.duration)
//
//        // 3. 采集视频
//        let videoAsset = AVURLAsset(url: videoURL)
//
//        // 4. 合成器创建一条空白的视频轨道
//        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
//        // 5. 获取视频内容轨道
//        guard let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
//            completion(nil, NSError(domain: "data nil", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: "视频内容为空"]))
//            return
//        }
//
//
//
//        // 9. 将视频、音频内容插入到相应的轨道中
//        do {
//            try videoTrack.insertTimeRange(videoTimeRange, of: videoAssetTrack, at: nextClistarTime)
//            try audioTrack.insertTimeRange(videoTimeRange, of: audioAssetTrack, at: nextClistarTime)
//        } catch {
//            completion(nil, error)
//        }
//
//        // 10. 创建导出session
//        export(with: composition, completion: completion)
//    }
    
    static func write(images: [UIImage], to path: String, size: CGSize, duration: Double, fps: Int, completeion: @escaping () -> Void) {
        
        guard let videoWriter = try? AVAssetWriter(url: URL(fileURLWithPath: path), fileType: .mov) else {
            print("创建AVAssetWriter失败")
            return
        }
        
        let videoSettings: [String : Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: size.width, AVVideoHeightKey: size.height]
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: nil)
        
        videoWriter.add(videoWriterInput)
        // start a session
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        // write some samples:
        var frameCount = 0
        let imagesCount = images.count
        // 每张图片所占的时间
        let averageTime = duration / Double(imagesCount)
        // 每张图片所占的帧数
        let averageFrame = Int(averageTime * Double(fps))
        
        autoreleasepool {
            for img in images {
                guard let buffer = img.pixelBuffer() else { continue }
                var append_ok = false
                autoreleasepool {
                    var j = 0
                    while !append_ok && j < 30 {
                        if adaptor.assetWriterInput.isReadyForMoreMediaData {
                            print("appending \(frameCount) attemp\(j)n", frameCount, j)
                            let frameTime = CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(fps))
                            let frameSeconds = CMTimeGetSeconds(frameTime)
                            print("frameCount:\(frameCount), kRecordingFPS:\(fps), frameSeconds:\(frameSeconds)")
                            append_ok = adaptor.append(buffer, withPresentationTime: frameTime)
//                            Thread.sleep(forTimeInterval: 0.05)
                        } else {
                            print("adaptor not ready \(frameCount), \(j)")
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                        j += 1
                    }
                    
                    if !append_ok {
                        print("error appending image \(frameCount) times \(j)")
                    }
                    frameCount = frameCount + averageFrame
                }
            }
        }
        
        // finish the session
        videoWriterInput.markAsFinished()
        videoWriter.finishWriting {
            print("finish writing")
            completeion()
        }
    }
    
    
    /// 裁切视频
    /// - Parameters:
    ///   - videoUr: 视频地址
    ///   - from: 开始时间，单位：秒
    ///   - to: 结束时间，单位：秒
    ///   - completion: 完成回调
    static func crop(videoURL: URL, from: Double, to: Double, completion: @escaping CompositionBlock) {
        
        // 2. 创建可变的音视频合成器
        let composition = AVMutableComposition()
        
        // 3. 采集视频
        let videoAsset = AVURLAsset(url: videoURL)
        // 4. 合成器创建一条空白的视频轨道
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        // 5. 获取视频内容轨道
        guard let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(Result.failure(NSError(domain: "data nil", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: "视频内容为空"])))
            return
        }
        
        // 6. 创建裁切的时间范围
        let startTime = CMTime(seconds: from, preferredTimescale: 600)
        let endTime = CMTime(seconds: to, preferredTimescale: 600)
        let cropTimeRange = CMTimeRange(start: startTime, end: endTime)
        
        // 7. 往空白的视频轨道开始的地方插入视频内容
        do {
            try videoTrack.insertTimeRange(cropTimeRange, of: videoAssetTrack, at: .zero)
        } catch {
            completion(Result.failure(error))
        }
        
        // 8. 这里可以处理原音频
        // ...
        
        // 9. 最后导出
        export(with: composition, completion: completion)
    }
    
}

private extension CompositionTool {
    
    @discardableResult
    static func audioTrack(with composition: AVMutableComposition, asset: AVURLAsset, start: CMTime, duration: CMTime, at trackStartTime: CMTime) -> [AVCompositionTrack]? {
        
        let audioAssetTracks = asset.tracks(withMediaType: .audio)
        guard audioAssetTracks.count > 0 else { return nil }
        
        var audioTracks = [AVCompositionTrack]()
        for audioAssetTrack in audioAssetTracks {
            // 合成器创建一条空白的音频轨道
            guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { continue }
            
            do {
                try audioTrack.insertTimeRange(CMTimeRange(start: start, duration: duration), of: audioAssetTrack, at: trackStartTime)
                audioTracks.append(audioTrack)
            } catch {
                continue
            }
        }
        return audioTracks
    }
    
    static func videoTracks(with composition: AVMutableComposition,
                            assetTrack: AVAssetTrack,
                            count: Int,
                            start: CMTime,
                            duration: CMTime,
                            at trackStartTime: CMTime) -> [AVCompositionTrack] {
        var tracks = [AVCompositionTrack]()
        
        for _ in 0..<count {
            guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { continue }
            try? videoTrack.insertTimeRange(CMTimeRange(start: start, duration: duration), of: assetTrack, at: trackStartTime)
            
            tracks.append(videoTrack)
        }
        
        return tracks
    }
    
    static func videoCompositionInstruction(with tracks: [AVAssetTrack], frameSize: CGSize, start: CMTime, duration: CMTime) -> AVMutableVideoCompositionInstruction {
        let count = tracks.count
        let width = Int(sqrt(Double(count)))
        var layerInstructions = [AVMutableVideoCompositionLayerInstruction]()
        for (index, assetTrack) in tracks.enumerated() {
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
            let ratio = 1.0 / CGFloat(width)
            let yRatio = width == 5 ? (1.0 / (CGFloat(width) - 0.1)) : ratio
            var transform = CGAffineTransform(scaleX: ratio, y: yRatio)
            
            let x = frameSize.width * CGFloat(index / width)
            let y = frameSize.height * CGFloat(index % width)
            
            transform = transform.translatedBy(x: x, y: y)
        
            layerInstruction.setTransform(transform, at: .zero)
            layerInstructions.append(layerInstruction)
        }
        
        let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
        videoCompositionInstruction.timeRange = CMTimeRange(start: start, duration: duration)
        videoCompositionInstruction.layerInstructions = layerInstructions
        
        return videoCompositionInstruction
    }
}

extension CompositionTool {
    static func duration(of videoUrl: URL) -> Double {
        let asset = AVURLAsset(url: videoUrl)
        return asset.duration.seconds
    }
    
    static func thumbImage(of videoUrl: URL, from: Double = 0) -> UIImage? {
        let asset = AVURLAsset(url: videoUrl)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: from, preferredTimescale: 1000)
        
        var actulTime = CMTime.zero
        guard let cgimage = try? gen.copyCGImage(at: time, actualTime: &actulTime) else { return nil }
        return UIImage(cgImage: cgimage)
    }
}

extension CompositionTool {
    static func export(with composition: AVMutableComposition, videoComposition: AVVideoComposition? = nil, fileName: String = "output", presetName: String = AVAssetExportPresetHighestQuality, completion: @escaping CompositionBlock) {
        guard let assetExport = AVAssetExportSession(asset: composition, presetName: presetName) else {
            completion(Result.failure(NSError(domain: "data nil", code: -3, userInfo: [NSLocalizedFailureReasonErrorKey: "导出Session为空"])))
            return
        }
        
        // 创建最终合成的视频输出的路径
        let outputFile = FilePath.fileURL(subPath: "/\(fileName).mov", shouldClear: true)
        
        // 配置导出信息，如导出格式，导出路径，是否为网络使用优化等
        assetExport.videoComposition = videoComposition
        assetExport.outputFileType = .mov
        assetExport.outputURL = outputFile
        assetExport.shouldOptimizeForNetworkUse = true
        
        // 开始导出
        assetExport.exportAsynchronously(completionHandler: { [weak assetExport] in
            guard let assetExport = assetExport else { return }
            
            switch assetExport.status {
            case .unknown:
                debugPrint("未知错误")
                completion(Result.failure(NSError(domain: "export failed", code: -4, userInfo: [NSLocalizedFailureReasonErrorKey: "发生未知错误"])))
            case .waiting:
                debugPrint("正在等待导出")
            case .cancelled:
                debugPrint("导出取消了")
                completion(Result.failure(NSError(domain: "export failed", code: -5, userInfo: [NSLocalizedFailureReasonErrorKey: "导出取消"])))
            case .exporting:
                debugPrint("正在导出: \(String(describing: assetExport.progress))")
            case .completed:
                debugPrint("导出完成")
                completion(Result.success(outputFile))
            case .failed:
                debugPrint("导出失败", assetExport.error ?? "")
                if let error = assetExport.error {
                    completion(Result.failure(NSError(domain: "export failed", code: -6, userInfo: [NSLocalizedFailureReasonErrorKey: error.localizedDescription])))
                    return
                }
                completion(Result.failure(NSError(domain: "export failed", code: -6, userInfo: [NSLocalizedFailureReasonErrorKey: "导出失败"])))
            default: break
            }
        })
        
        check(export: assetExport, on: exportQueue)
    }
}
