//
//  TorchModule.m
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/16.
//

#import "TorchModule.h"
#import <LibTorch-Lite/Libtorch-Lite.h>


using namespace std;

@implementation TorchModule {
    torch::jit::mobile::Module _model;
}

- (instancetype)initWithFileAtPath:(NSString *)filePath {
    if (self = [super init]) {
        try {
            _model = torch::jit::_load_for_mobile(filePath.UTF8String);
        } catch (const std::exception& exception) {
            NSLog(@"%s", exception.what());
            return nil;
        }
    }
    return self;
}


- (void)runKpDetect:(void *)imageBuffer with:(int)width height:(int)height completion:(void(^)(NSArray<NSNumber *> *values, NSArray<NSNumber *> *jacobans))completion {
    
    at::Tensor tensor = torch::from_blob(imageBuffer, {1, 3, width, height}, at::kFloat);
    
//    auto test = _model.forward({ tensor });
//    cout << test << endl;
    
    auto outputDict = _model.forward({ tensor }).toGenericDict();
    
    auto valueTensor = outputDict.at("value").toTensor();
    auto jacobianTensor = outputDict.at("jacobian").toTensor();
    
    float *valueBuffer = valueTensor.data_ptr<float>();
    float *jacobianBuffer = jacobianTensor.data_ptr<float>();
    
    int64_t dim = valueTensor.dim();
    
    int valueCount = 1;
    for (int i = 0; i < dim; i++) {
        int64_t size = valueTensor.size(i);
        valueCount *= size;
    }
    
    dim = jacobianTensor.dim();
    int jacobianCount = 1;
    for (int i = 0; i < dim; i++) {
        int64_t size = jacobianTensor.size(i);
        jacobianCount *= size;
    }
    
    NSMutableArray* values = [NSMutableArray array];
    for (int i = 0; i < valueCount; i++) {
        [values addObject:@(valueBuffer[i])];
    }

    NSMutableArray* jacobians = [NSMutableArray array];
    for (int i = 0; i < jacobianCount; i++) {
        [jacobians addObject:@(jacobianBuffer[i])];
    }
    
    completion(values.copy, jacobians.copy);
}

- (NSArray<NSNumber *> *)runGenerator:(void *)imageBuffer with:(int)width height:(int)height kp_driving:(nonnull NSDictionary *)drivingDict kp_source:(nonnull NSDictionary *)sourceDict {
    
    #pragma mark - 将 kp_driving 和 kp_source 都转成 torch::IValue, 具体是字典形式
    
    /// 1. 取出 OC 字典中的数组
    NSArray<NSNumber *> *value = drivingDict[@"value"];
    NSArray<NSNumber *> *jacobian = drivingDict[@"jacobian"];
    
    NSArray<NSNumber *> *source_value = sourceDict[@"value"];
    NSArray<NSNumber *> *source_jacobian = sourceDict[@"jacobian"];
    
    /// 2. 转换成 c 指针数组
    float *val = (float *)malloc(sizeof(float) * value.count);
    float *jac = (float *)malloc(sizeof(float) * jacobian.count);
    
    float *source_val = (float *)malloc(sizeof(float) * source_value.count);
    float *source_jac = (float *)malloc(sizeof(float) * source_jacobian.count);
    
    [value enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        val[idx] = obj.floatValue;
    }];
    
    [jacobian enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        jac[idx] = obj.floatValue;
    }];
    
    [source_value enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        source_val[idx] = obj.floatValue;
    }];
    
    [source_jacobian enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        source_jac[idx] = obj.floatValue;
    }];
    
    /// 3. 转成 c++ vector 容器
    vector<float> vec_val(val, val + value.count);
    vector<float> vec_jac(jac, jac + jacobian.count);
    
    vector<float> source_vec_val(source_val, source_val + source_value.count);
    vector<float> source_vec_jac(source_jac, source_jac + source_jacobian.count);
    
    /// 4. 转成 Tensor
    torch::Tensor val_tensor = torch::tensor(vec_val).reshape({ 1, 10, 2 });
    torch::Tensor jac_tensor = torch::tensor(vec_jac).reshape({ 1, 10, 2, 2 });
    
    torch::Tensor source_val_tensor = torch::tensor(source_vec_val).reshape({ 1, 10, 2 });
    torch::Tensor source_jac_tensor = torch::tensor(source_vec_jac).reshape({ 1, 10, 2, 2 });
    
    /// 5. 创建 Dict 并将 value 和 jacobian 设置进去
    c10::Dict<string, torch::Tensor>(kp_driving);
    kp_driving.insert("value", val_tensor);
    kp_driving.insert("jacobian", jac_tensor);
    
    c10::Dict<string, torch::Tensor>(kp_source);
    kp_source.insert("value", source_val_tensor);
    kp_source.insert("jacobian", source_jac_tensor);

    /// 6. 将 Dict 转换成 IValue
    torch::IValue driving(kp_driving);
    torch::IValue source(kp_source);
    
    /// 图片数据
    at::Tensor image = torch::from_blob(imageBuffer, {1, 3, width, height}, at::kFloat).metal();
    
    CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
    
    /// 调用模型
    auto outputDict = _model.forward({ image, driving, source }).toGenericDict();
    
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    
    NSLog(@"调用一次generator所花的时间:%2fs", end - begin);
    
    auto prediction = outputDict.at("prediction").toTensor().cpu();
    
    float *valueBuffer = prediction.data_ptr<float>();
    
    
    int64_t dim = prediction.dim();
    
    int valueCount = 1;
    for (int i = 0; i < dim; i++) {
        int64_t size = prediction.size(i);
        valueCount *= size;
    }
    
    NSMutableArray* values = [NSMutableArray array];
    for (int i = 0; i < valueCount; i++) {
        [values addObject:@(valueBuffer[i])];
    }
    
    free(val);
    free(jac);
    free(source_val);
    free(source_jac);
    
    return values.copy;
}

@end
