//
//  File.swift
//
//
//  Created by Nemo on 2020/7/16.
//

import Foundation

public final class Disposable {
    typealias AddHandler = ((AnyObject?) -> ())
    typealias RemoveHandler = () -> Bool
    
    private let add: AddHandler
    private let remove: RemoveHandler
    
    init(addHandler: @escaping AddHandler, removeHandler: @escaping RemoveHandler) {
        add = addHandler
        remove = removeHandler
    }
    
    /// 手动移除观察
    /// - Returns: 是否成功
    @discardableResult
    public func dispose() -> Bool {
        return remove()
    }
    
    /// 改变观察周期跟随对象生命周期
    /// - Parameter object: 对象
    /// - Returns: self
    @discardableResult
    public func add(to object: AnyObject?) -> Disposable {
        add(object)
        return self
    }
    
    /// 改变观察周期跟随自身生命周期
    /// - Returns: self
    @discardableResult
    public func unowned() -> Disposable {
        return add(to: self)
    }
    
    /// 改变观察周期跟随清除包生命周期
    /// - Parameter bag: 清除包
    @discardableResult
    public func add(to bag: DisposeBag) -> Disposable {
        bag.add(self)
        return add(to: bag as AnyObject?)
    }
}
