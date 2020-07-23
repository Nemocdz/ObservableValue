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
    
    /// 改变为跟随对象生命周期移除监听
    /// - Parameter object: 对象
    /// - Returns: self
    @discardableResult public func add(to object: AnyObject?) -> Disposable {
        add(object)
        return self
    }
    
    /// 改变为跟随自身生命周期移除监听
    /// - Returns: self
    @discardableResult public func unowned() -> Disposable {
        return add(to: self)
    }
    
    /// 手动移除监听
    /// - Returns: 是否成功
    @discardableResult public func dispose() -> Bool {
        return remove()
    }
}


