//
//  FaceUtils.swift
//  FaceAnimationTest
//
//  Created by zhangerbing on 2021/8/18.
//

import Foundation

struct FaceUtils {
    static func hard_nms(scores: [Float], boxes: [[Float]], iou_threshold: Float = 0.5, top_k: Int = -1, candidate_size: Int = 200) -> (confidence: [Float], boxes: [[Float]]) {
        var picked = [Int]()
        
        // 这里python代码中会从indices的[-candiate_size:]切片，这里感觉没什么必要就没有做切片
        var indices = scores.argsort()
            
        while indices.count > 0 {
            guard let current = indices.last else { break }
            picked.append(current)
            
            if picked.count == top_k && top_k > 0 || indices.count == 1 {
                break
            }
            
            let current_box = boxes[current]
            indices = indices.dropLast()
            let rest_boxes = boxes[indices]
            
            let iou = iou_of(boxes0: rest_boxes, boxes1: [current_box])
            
            indices = indices.enumerated().compactMap({ item in
                iou[item.offset] <= iou_threshold ? item.element : nil
            })
        }
        
        let pickConfidences = scores[picked]
        let pickBoxes = boxes[picked]
        
        return (pickConfidences, pickBoxes)
    }
    
    
    /// 计算框框间的IOU
    /// - Parameters:
    ///   - boxes0: boxes0 坐标数组, shape [N, 4]
    ///   - boxes1: boxes1 坐标数组, shape [4，]
    ///   - eps: 很小的数，避免0作为分母
    static func iou_of(boxes0: [[Float]], boxes1: [[Float]], eps: Float = 1e-5) -> [Float] {
        // 分别将 boxes0 和boxes1 每项的前两列 以及后两列
        let boxes0_left_top = boxes0.map { Array($0[..<2]) }
        let boxes1_left_top = boxes1.map { Array($0[..<2]) }
        
        let boxes0_right_bottom = boxes0.map { Array($0[2...]) }
        let boxes1_right_bottom = boxes1.map { Array($0[2...]) }
        
        // 取出最大的框
        let overlap_left_top = maximum(x: boxes0_left_top, y: boxes1_left_top[0])
        let overlap_right_bottom = minimum(x: boxes0_right_bottom, y: boxes1_right_bottom[0])
        
        // 计算出面积
        let overlap_area = area_of(left_top: overlap_left_top, right_bottom: overlap_right_bottom)
        let area0 = area_of(left_top: boxes0_left_top, right_bottom: boxes0_right_bottom)
        let area1 = area_of(left_top: boxes1_left_top, right_bottom: boxes1_right_bottom)
        
        let iou = overlap_area.enumerated().map { item in
            item.element / (area0[item.offset] + area1[0] - item.element + eps)
        }
        
        return iou
    }
    
    static func area_of(left_top: [[Float]], right_bottom: [[Float]]) -> [Float] {
        let widths_heights = (right_bottom - left_top).map { $0.map { $0.clamp(to: 0...Float.greatestFiniteMagnitude) } }
        return widths_heights.map { ($0.first ?? 0.0) * ($0.last ?? 0.0) }
    }
}

private extension FaceUtils {
    static func maximum(x: [[Float]], y: [Float]) -> [[Float]] {
        x.map { item in
            var temp = item
            for (index, element) in item.enumerated() {
                temp[index] = max(element, y[index])
            }
            return temp
        }
    }
    
    static func minimum(x: [[Float]], y: [Float]) -> [[Float]] {
        x.map { item in
            var temp = item
            for (index, element) in item.enumerated() {
                temp[index] = min(element, y[index])
            }
            return temp
        }
    }
}
