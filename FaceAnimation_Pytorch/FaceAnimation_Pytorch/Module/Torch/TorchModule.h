//
//  TorchModule.h
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TorchModule : NSObject

- (nullable instancetype)initWithFileAtPath:(NSString *)filePath;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (void)runKpDetect:(void *)imageBuffer with:(int)width height:(int)height completion:(void(^)(NSArray<NSNumber *> *values, NSArray<NSNumber *> *jacobans))completion;

- (void)runGenerator:(void *)imageBuffer with:(int)width height:(int)height kp_driving:(NSDictionary *)drivingDict kp_source:(NSDictionary *)sourceDict;

@end

NS_ASSUME_NONNULL_END
