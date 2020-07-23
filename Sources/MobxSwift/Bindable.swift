//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/19.
//

import Foundation

@propertyWrapper
public struct Bindable<Value> {
    public let projectedValue: Observeable<Value>
    
    public init(wrappedValue: Value) {
        projectedValue = Observeable(wrappedValue)
    }
    
    public var wrappedValue: Value {
        get { projectedValue.value }
        set { projectedValue.update(newValue) }
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
    /// Optional -> Optional || Wrapped -> Wrapped
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
    /// Wrapped -> Optional
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

extension Observeable where Value: ObservableOptionalValue {
    
    /// 值改变时修改响应者 KeyPath
    /// Optional -> Wrapped
    /// - Parameters:
    ///   - receiver: 响应者
    ///   - receiverKeyPath: 响应者 KeyPath
    /// - Returns: 可移除监听者
    @discardableResult public func bind<R>(to receiver: R, at keyPath: ReferenceWritableKeyPath<R, Value.Wrapped>) -> Disposable where R: AnyObject {
        return bind(to: receiver) { receiver, newValue in
            guard !newValue.isNil else { return }
            receiver[keyPath: keyPath] = newValue.wrapped
        }
    }
}
