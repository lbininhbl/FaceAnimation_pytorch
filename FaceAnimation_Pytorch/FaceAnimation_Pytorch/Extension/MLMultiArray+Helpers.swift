//
//  MLMultiArray+Helpers.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/10/27.
//

import CoreML

extension MLMultiArray {
    
    @nonobjc public func reshaped(to dimensions: [Int]) throws -> MLMultiArray {
        let newCount = dimensions.reduce(1, *)
        assert(newCount == count, "Cannot reshape \(shape) to \(dimensions)")
        
        var newStrides = [Int](repeating: 0, count: dimensions.count)
        newStrides[dimensions.count - 1] = 1
        for i in stride(from: dimensions.count - 1, to: 0, by: -1) {
            newStrides[i - 1] = newStrides[i] * dimensions[i]
        }
        
        let newShape = dimensions.map { NSNumber(value: $0) }
        let newStride = newStrides.map { NSNumber(value: $0) }
        
        return try MLMultiArray(dataPointer: dataPointer, shape: newShape, dataType: dataType, strides: newStride)
    }
    
    @nonobjc public func transposed(to order: [Int]) throws -> MLMultiArray {
        let ndim = order.count

//        precondition(dataType == .double)
        precondition(ndim == strides.count)
        
        let newShape = shape.indices.map { shape[order[$0]] }
        let newArray = try MLMultiArray(shape: newShape, dataType: self.dataType)
        
        let srcPtr = UnsafeMutablePointer<Float32>(OpaquePointer(dataPointer))
        let dstPtr = UnsafeMutablePointer<Float32>(OpaquePointer(newArray.dataPointer))
        
        let srcShape = shape.map { $0.intValue }
        let dstStride = newArray.strides.map { $0.intValue }
        var idx = [Int](repeating: 0, count: ndim)
        
        for j in 0..<count {
            // Map the source index to the destination index.
            var dstIndex = 0
            for i in 0..<ndim {
                dstIndex += idx[order[i]] * dstStride[i]
            }
            
            // Copy the value.
            dstPtr[dstIndex] = srcPtr[j]
            
            // Update the source index.
            var i = ndim - 1
            idx[i] += 1
            while i > 0 && idx[i] >= srcShape[i] {
                idx[i] = 0
                idx[i - 1] += 1
                i -= 1
            }
        }
        return newArray
    }
}
