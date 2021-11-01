//
//  OpenCVWrapper.h
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/10/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (instancetype)shared;

+ (UIImage *)bgrImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
