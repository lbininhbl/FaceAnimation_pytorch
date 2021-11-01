//
//  Math.swift
//  FaceAnimation_Pytorch_CoreML
//
//  Created by zhangerbing on 2021/10/27.
//

import Foundation

/** Ensures that `x` is in the range `[min, max]`. */
public func clamp<T: Comparable>(_ x: T, min: T, max: T) -> T {
  if x < min { return min }
  if x > max { return max }
  return x
}
