//
//  File.swift
//
//
//  Created by Nemo on 2020/7/19.
//

import Foundation

@propertyWrapper
public class Bindable<Value> {
    public let projectedValue: Observable<Value>
    
    public init(wrappedValue: Value) {
        projectedValue = Observable(wrappedValue)
    }
    
    public var wrappedValue: Value {
        get { projectedValue.value }
        set { projectedValue.update(newValue) }
    }
}

// MARK: Bind

public extension Observable {
    /// 语法糖 = addObserver + add(to: receiver)
    /// 马上执行一次事件
    /// - Parameters:
    ///   - receiver: 响应者
    ///   - receiveHandler: 接收新值时的处理
    /// - Returns: 可移除监听者
    @discardableResult
    func bind<R>(to receiver: R, receiveHandler: @escaping (R, Value) -> ()) -> Disposable where R: AnyObject {
        receiveHandler(receiver, value)
        return addObserver { [weak receiver] change in
            guard let receiver = receiver else { return }
            receiveHandler(receiver, change.newValue)
        }.add(to: receiver)
    }
    
    /// 值改变时修改响应者 KeyPath
    /// Optional -> Optional / Wrapped -> Wrapped
    /// - Parameters:
    ///   - receiver: 响应者
    ///   - receiverKeyPath: 响应者 KeyPath
    /// - Returns: 可移除监听者
    @discardableResult
    func bind<R>(to receiver: R, at keyPath: ReferenceWritableKeyPath<R, Value>) -> Disposable where R: AnyObject {
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
    @discardableResult
    func bind<R>(to receiver: R, at keyPath: ReferenceWritableKeyPath<R, Value?>) -> Disposable where R: AnyObject {
        return bind(to: receiver) { receiver, newValue in
            receiver[keyPath: keyPath] = newValue as Value?
        }
    }
}

public extension Observable where Value: ObservableOptional {
    /// 值改变时修改响应者 KeyPath
    /// Optional -> Wrapped
    /// - Parameters:
    ///   - receiver: 响应者
    ///   - receiverKeyPath: 响应者 KeyPath
    /// - Returns: 可移除监听者
    @discardableResult
    func bind<R>(to receiver: R, at keyPath: ReferenceWritableKeyPath<R, Value.Wrapped>) -> Disposable where R: AnyObject {
        return bind(to: receiver) { receiver, newValue in
            guard !newValue._isNil else { return }
            receiver[keyPath: keyPath] = newValue._wrapped
        }
    }
}
