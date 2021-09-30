//
//  BaseCoordinator.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/23.
//

import Foundation
import RxSwift

/// 基层的抽象 coordinator ，在 `start` 方法返回通用的类型
class BaseCoordinator<ResultType> {
    
    /// 允许通过 `CoodinatorName.CoordinationResult`访问 coordinator 的泛型的别名
    typealias CoordinationResult = ResultType
    
    /// 子类实用的工具 `DisposeBag`
    let disposeBag = DisposeBag()
    
    /// 唯一标记
    private let identifier = UUID()
    
    
    /// 储存子 coordinators 的字典，为了在内存中持有，每一个子 coordinator 都必须加到字典中。
    /// Key 是子 coordinator 的 `identifier`，而 value 就是 子 coordinator 本身
    /// Value 是 `Any`类型，因为 Swift 不允许在字典中储存泛型。
    private var childCoordinators = [UUID: Any]()
    
    
    /// 储存 coordinator 到 `childCoordinators` 字典中
    /// - Parameter coordinator: 要保存的 coordinator
    private func store<T>(coordinator: BaseCoordinator<T>) {
        childCoordinators[coordinator.identifier] = coordinator
    }
    
    /// 从 `childCoordinators` 中释放 coordinator
    /// - Parameter coordinator: 要释放的 coordinator
    private func free<T>(coordinator: BaseCoordinator<T>) {
        childCoordinators[coordinator.identifier] = nil
    }
    
    
    /// 1. 储存 coordinator 在 child coordinators 字典中
    /// 2. 调用 `start()` 方法
    /// 3. 在 `start()` 方法中返回的可观察对象中的 `onNext:` 方法中将 coordinator 从字典中释放掉
    /// - Parameter coordinator: 将要执行的 coordinator
    /// - Returns: `start()` 方法返回的结果
    func coordinate<T>(to coordinator: BaseCoordinator<T>) -> Observable<T> {
        store(coordinator: coordinator)
        return coordinator.start()
            .do(onNext: { [weak self] _ in  self?.free(coordinator: coordinator) })
    }
    
    
    /// 开始 coordinator 的工作
    /// - Returns: coordinator 执行后的结果
    func start() -> Observable<ResultType> {
        fatalError("Start method should be implemented.")
    }
    
    deinit {
        print(String(describing: Self.self) + "释放了")
    }
}
