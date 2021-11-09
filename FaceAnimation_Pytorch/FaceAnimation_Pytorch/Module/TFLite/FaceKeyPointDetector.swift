//
//  FaceKeyPointDetector.swift
//  FaceAnimationTest
//
//  Created by zhangerbing on 2021/8/19.
//

import Foundation
import TensorFlowLite

class FaceKeyPointDetector: ModelDataHandler {
    
    var normalizeRange: NormalizeRange = .negative_to_one
    
    let inputWidth: Int = 96
    let inputHeight: Int = 96
    
    var interpreter: Interpreter
    
    required init?(model: TFLiteModel, threadCount: Int = 1) {
        let modelFileName = model.name
        let fileExtension = model.extension
        
        // 加载模型文件
        guard let modelPath = Bundle.main.path(forResource: modelFileName, ofType: fileExtension) else { return nil }
        
        var options = Interpreter.Options()
        options.threadCount = threadCount
        
        do {
            var option = CoreMLDelegate.Options()
            option.enabledDevices = .all
            option.coreMLVersion = 3
            var delegate: Delegate? = CoreMLDelegate(options: option)
            
            if delegate == nil {
                delegate = MetalDelegate()
            }
            // 创建解析器
            interpreter = try Interpreter(modelPath: modelPath, options: options, delegates: [delegate!])
//            interpreter = try Interpreter(modelPath: modelPath, options: options)
            try interpreter.allocateTensors()
            
        } catch {
            let error = error as NSError
            print("创建解析器失败:", error.localizedDescription)
            return nil
        }
        
        print("\(modelFileName)创建成功，输入:\(interpreter.inputTensorCount)个, 输出:\(interpreter.outputTensorCount)个")
    }
    
    // MARK: - 运行模型
    func runModel(onFrame pixelBuffer: CVPixelBuffer) -> Any? {
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        assert(
            sourcePixelFormat == kCVPixelFormatType_32ARGB ||
            sourcePixelFormat == kCVPixelFormatType_32BGRA ||
            sourcePixelFormat == kCVPixelFormatType_32RGBA
        )
        
        let scaledSize = CGSize(width: inputWidth, height: inputHeight)
        guard let thumbnailPixelBuffer = pixelBuffer.resize(to: scaledSize) else { return nil }
        
        let outputTensor: Tensor
        do {
            
            guard let rgbData = rgbDataFromBuffer(thumbnailPixelBuffer, byteCount: inputWidth * inputHeight * inputchannels) else {
                print("图像转换成RGB数据失败")
                return nil
            }
            
            // 把RGB数据传入到解析器的第一个Tensor中
            try interpreter.copy(rgbData, toInputAt: 0)
            
            // 执行解析器
            try interpreter.invoke()
            
            outputTensor = try interpreter.output(at: 0)
            
        } catch let error {
            print("执行解析器失败: ", error.localizedDescription)
            return nil
        }
        
        // 处理结果数据
        let result = [Float](unsafeData: outputTensor.data) ?? []
        return result
    }
}
