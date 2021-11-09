//
//  AlbumUtils.swift
//  FaceAnimation_tensorflowlite
//
//  Created by zhangerbing on 2021/9/29.
//

import Foundation
import RxSwift
import Photos

struct AlbumUtils {
    static func save(url: URL?) -> Completable {
        return Completable.create { observer in
            let disposables = Disposables.create()
            
            guard let url = url else {
                let error = NSError(domain: "data nil", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有可保存的视频"])
                observer(.error(error))
                return disposables
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    success ? observer(.completed) : observer(.error(error!))
                }
            }
            return disposables
        }
    }
}
