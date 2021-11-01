//
//  PlayUtil.swift
//  VideoComposition
//
//  Created by zhangerbing on 2021/4/8.
//

import UIKit
import AVFoundation

class PlayUtil: NSObject {
    
    static let shared: PlayUtil = PlayUtil()
    
    private let player = AVPlayer()
    
    private override init() {}
    
    func play(url: URL, on view: UIView? = nil) {
        let playerItem = AVPlayerItem(url: url)
        play(playerItem: playerItem, on: view)
    }
    
    func play(playerItem: AVPlayerItem, on view: UIView? = nil) {
        player.replaceCurrentItem(with: nil)
        player.replaceCurrentItem(with: playerItem)
        
        if let view = view {
            view.layer.sublayers?.forEach({ layer in
                if layer is AVPlayerLayer {
                    layer.removeFromSuperlayer()
                }
            })
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = view.bounds
            playerLayer.videoGravity = .resizeAspect
            view.layer.addSublayer(playerLayer)
        }
        player.play()
        
        playerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayFinish), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    
    @objc func onPlayFinish() {
        print("播放完毕")
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
}

extension PlayUtil {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem else { return }
        
        if let keyPath = keyPath, keyPath == "status" {
            switch item.status {
            case .readyToPlay:
                print("准备播放")
            case .failed:
                print("播放失败", item.error!)
            case .unknown:
                print("未知错误")
            @unknown default:
                fatalError("空")
            }
        }
    }
}
