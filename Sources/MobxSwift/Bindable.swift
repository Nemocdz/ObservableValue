//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/19.
//

import Foundation

@propertyWrapper
public final class Bindable<Value> {
    private let observable: Observeable<Value>
    
    public init(wrappedValue: Value) {
        observable = Observeable(wrappedValue)
    }
    
    public var projectedValue: Observeable<Value> {
        return observable
    }
    
    public var wrappedValue: Value {
        get { observable.value }
        set { observable.update(newValue) }
    }
}

extension Observeable {
    
    /// 语法糖 = addObserver + add(to: receiver)
    /// 马上执行一次事件
    /// - Parameters:
    ///   - receiver: 响应者
    ///   - handler: 执行事件
    /// - Returns: 可移除监听者
    @discardableResult public func bind<R>(to receiver: R, handler: @escaping (R, Value) -> ()) -> Disposable where R: AnyObject {
        handler(receiver, value)
        return addObserver { [weak receiver] change in
            guard let receiver = receiver else { return }
            handler(receiver, change.newValue)
        }.add(to: receiver)
    }
    
    /// 值改变时修改响应者 KeyPath
    /// - Parameters:
    ///   - receiver: 响应者
    ///   - receiverKeyPath: 响应者 KeyPath
    /// - Returns: 可移除监听者
    @discardableResult public func bind<R>(to receiver: R, at keyPath: ReferenceWritableKeyPath<R, Value>) -> Disposable where R: AnyObject {
        return bind(to: receiver) { receiver, newValue in
            receiver[keyPath: keyPath] = newValue
        }
    }
    
    /// 值改变时修改响应者 KeyPath
    /// - Parameters:
    ///   - receiver: 响应者
    ///   - receiverKeyPath: 响应者 KeyPath
    /// - Returns: 可移除监听者
    @discardableResult public func bind<R>(to receiver: R, at keyPath: ReferenceWritableKeyPath<R, Value?>) -> Disposable where R: AnyObject {
        return bind(to: receiver) { receiver, newValue in
            receiver[keyPath: keyPath] = newValue as Value?
        }
    }
}
