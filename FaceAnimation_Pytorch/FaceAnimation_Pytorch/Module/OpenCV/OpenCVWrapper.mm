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

@interface OpenCVWrapper() {
    Mat _inv_mat; // 临时
    Mat _img_T; // 临时
    Mat _trans_mat;
}

@end

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

#pragma mark - Private
+ (Mat)matFrom:(UIImage *)source {
    cout << "matFrom ->";
    
    CGImageRef imageRef = CGImageCreateCopy(source.CGImage);
    
    CGFloat cols = CGImageGetWidth(imageRef);
    CGFloat rows = CGImageGetHeight(imageRef);
    
    Mat result(rows, cols, CV_8UC4, Scalar(1, 2, 3, 4));
    
    
    size_t bitsPercomponent = 8;
    size_t bytesPerRow = result.step[0];
    
    CGColorSpaceRef colorSpaceRef = CGImageGetColorSpace(imageRef);
    CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
    
    CGContextRef context = CGBitmapContextCreate(result.data, cols, rows, bitsPercomponent, bytesPerRow, colorSpaceRef, bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, cols, rows), imageRef);
    
    CGContextRelease(context);
    
    return result;
}

- (UIImage *)alignFaceImage:(UIImage *)image from:(NSArray *)from to:(NSArray *)to fromRow:(int)fromRow fromCol:(int)fromCol toRow:(int)toRow toCol:(int)toCol size:(CGSize)size {
   
    Mat imgMat;
    UIImageToMat(image, imgMat);
    cvtColor(imgMat, imgMat, COLOR_RGBA2BGRA);
    
    int **fromArray = [self getArrayFrom:from];
    int **toArray = [self getArrayFrom:to];
    
    Mat fromMat = [self Vec2Mat:fromArray type:CV_16U row:fromRow col:fromCol];
    Mat toMat = [self Vec2Mat:toArray type:CV_16U row:toRow col:toCol];
    
    free(fromArray);
    free(toArray);
    
    Mat trans_mat = estimateAffinePartial2D(fromMat, toMat);
    
    Mat img_T;
    warpAffine(imgMat, img_T, trans_mat, Size2i(size.width, size.height));
    _img_T = img_T;
    
    _trans_mat = trans_mat;
    
    // 再反过来
    Mat inv_mat;
    invertAffineTransform(_trans_mat, inv_mat);
    _inv_mat = inv_mat;
    
    UIImage *newImage = MatToUIImage(img_T);
    
    return newImage;
}

- (CVPixelBufferRef)fusionPrediction:(CVPixelBufferRef)prediction mask:(NSArray * _Nullable)mask sourceImage:(UIImage *)sourceImage {
    
    // 原图
    Mat imgMat;
    UIImageToMat(sourceImage, imgMat);
    
    
    // mask
    Mat fusion_mask = [self getMatFromArray:mask];
    
    // 人脸部分
    Mat alignedFace0;
    _img_T.copyTo(alignedFace0);
    cvtColor(alignedFace0, alignedFace0, COLOR_BGRA2RGBA);
    alignedFace0.convertTo(alignedFace0, CV_32FC4);
    alignedFace0 = alignedFace0 / 255.0;
    
    // 预测帧，转Mat
    Mat pred = MatFromCVPixelBuffer(prediction);
    pred.convertTo(pred, CV_32FC4);
    pred = pred / 255.0;
    
    // 执行fuse公式
    Mat n(fusion_mask.rows, fusion_mask.cols, fusion_mask.type(), Scalar(1, 1, 1, 1));
    Mat fuse_pred = fusion_mask.mul(pred) + (n - fusion_mask).mul(alignedFace0);
    
    Mat fuse_pred_uint8;
    fuse_pred = fuse_pred * 255;
    fuse_pred.convertTo(fuse_pred_uint8, CV_8UC4);
    
    // warp操作
    warpAffine(fuse_pred_uint8, imgMat, _inv_mat, Size2i(sourceImage.size.width, sourceImage.size.height), INTER_LINEAR, BORDER_TRANSPARENT);
    
    cvtColor(imgMat, imgMat, COLOR_BGRA2RGBA);
    
    CVPixelBufferRef pixelBuffer = PixelBufferFromMat(imgMat);
    
    return pixelBuffer;
}


- (int **)getArrayFrom:(NSArray *)array {
    NSInteger count = array.count;
    int **p = (int **)malloc(count * sizeof(int *));
    
    for (int i = 0; i < count; i++) {
        
        NSArray<NSNumber *> *temp = array[i];
        int *temp_p = (int *)malloc(temp.count * sizeof(int));
        [temp enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            temp_p[idx] = [obj intValue];
        }];
        
        p[i] = temp_p;
    }
    return p;
}


- (Mat)getMatFromArray:(NSArray *)array {
    NSUInteger row = 256;
    NSUInteger col = 256;
    NSUInteger channel = 4;
    
    float *d1 = (float *)malloc(sizeof(float) * row * col * channel);
    
    // 这里不能顺着取
    for (NSUInteger i = 0; i < row; i++) {
        NSArray *rows = array[i];
        for (NSUInteger j = 0; j < col; j++) {
            NSArray *cols = rows[j];
            for (NSUInteger k = 0; k < channel; k++) {
                NSUInteger index = i * col * channel + j * channel + k;
                if (k == 3) {
                    d1[index] = 1.0;
                } else {
                    float value = [cols[k] floatValue];
                    d1[index] = value;
                }
            }
        }
    }
    
    int type = channel == 4 ? CV_32FC4 : CV_32FC3;
    Mat b(Size2l(row, col), type, d1);
    
//    free(d1);
    
    return b;
}

- (Mat)Vec2Mat:(int **)array type:(int)type row:(int)row col:(int)col {
    Mat mat(row, col, type);
    
    UInt16 *ptemp = NULL;
    
    for (int i = 0; i < row; i++) {
        ptemp = mat.ptr<UInt16>(i);
        for (int j = 0; j < col; j++) {
            ptemp[j] = array[i][j];
        }
    }
    
    return mat;
}

- (void)enumMat:(Mat)mat {
    cout << mat << endl;
}


Mat MatFromCVPixelBuffer(CVPixelBufferRef pixelBuffer) {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    int bytePerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    Mat image = Mat(bufferHeight, bufferWidth, CV_8UC4, pixel, bytePerRow);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return image;
}

CVPixelBufferRef PixelBufferFromMat(Mat mat) {
    cvtColor(mat, mat, CV_BGR2BGRA);
    
    int widthReminder = mat.cols % 64, heightReminder = mat.rows % 64;
    if (widthReminder != 0 || heightReminder != 0) {
        resize(mat, mat, cv::Size(mat.cols + (64 - widthReminder), mat.rows + (64 - heightReminder)));
    }
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             [NSNumber numberWithInt:mat.cols], kCVPixelBufferWidthKey,
                             [NSNumber numberWithInt:mat.rows], kCVPixelBufferHeightKey,
                             [NSNumber numberWithInteger:mat.step[0]], kCVPixelBufferBytesPerRowAlignmentKey,
                             nil];
    
    CVPixelBufferRef imageBuffer;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorMalloc, mat.cols, mat.rows, kCVPixelFormatType_32BGRA, (CFDictionaryRef)CFBridgingRetain(options), &imageBuffer);
    assert(status == kCVReturnSuccess && imageBuffer != NULL);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *base = CVPixelBufferGetBaseAddress(imageBuffer);
    memcpy(base, mat.data, mat.total() * mat.elemSize());
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return imageBuffer;
}

@end
