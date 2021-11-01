//
//  OpenCVWrapper.m
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/10/28.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/core/types.hpp>
#import <opencv2/calib3d/calib3d_c.h>

using namespace std;
using namespace cv;

@implementation OpenCVWrapper

+ (instancetype)shared {
    static OpenCVWrapper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OpenCVWrapper alloc] init];
    });
    return instance;
}

+ (NSString *)openCVVersion {
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}

+ (UIImage *)bgrImage:(UIImage *)image {
    Mat imgMat;
    UIImageToMat(image, imgMat);
    cvtColor(imgMat, imgMat, COLOR_RGBA2BGRA);
    
    UIImage *newImage = MatToUIImage(imgMat);
    return newImage;
}

@end
