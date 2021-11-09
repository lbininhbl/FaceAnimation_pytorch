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

- (UIImage *)alignFaceImage:(UIImage *)image from:(NSArray *_Nullable)from to:(NSArray *_Nullable)to fromRow:(int)fromRow fromCol:(int)fromCol toRow:(int)toRow toCol:(int)toCol size:(CGSize)size;


- (NSArray<UIImage *> *)fusion:(NSArray *_Nullable)predictions mask:(NSArray *_Nullable)mask sourceImage:(UIImage *)sourceImage progress:(void(^)(float))progress;

- (CVPixelBufferRef)fusionPrediction:(CVPixelBufferRef)prediction mask:(NSArray * _Nullable)mask sourceImage:(UIImage *)sourceImage;

@end

NS_ASSUME_NONNULL_END
