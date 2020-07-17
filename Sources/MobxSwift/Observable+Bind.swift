//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/16.
//

import Foundation

extension Observeable {
    // 0
    @discardableResult
    public func bind<R>(to receiver: R, at queue: DispatchQueue? = nil, handler: @escaping (R, ObservedChange<Value>) -> ()) -> AnyObserver where R: AnyObject {
        let observer = addObserver { [weak receiver] change in
            guard let receiver = receiver else { return }
            if let queue = queue {
                queue.async {
                    handler(receiver, change)
                }
            } else {
                handler(receiver, change)
            }
        }
        observer.store(in: receiver)
        return observer
    }
    
    // 1 -> 0
    @discardableResult
    public func bind<R, V>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, V>, at queue: DispatchQueue? = nil, transform: @escaping (Value) -> V) -> AnyObserver where R: AnyObject {
        return bind(to: receiver, at: queue) { receiver, change in
            receiver[keyPath: receiverKeyPath] = transform(change.newValue)
        }
    }
    
    // -> 1
    @discardableResult
    public func bind<R>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, Value>, at queue: DispatchQueue? = nil) -> AnyObserver where R: AnyObject {
        let transform: (Value) -> Value = { $0 }
        return bind(to: receiver, receiverKeyPath, at: queue, transform: transform)
    }
    
    // -> 1
    @discardableResult
    public func bind<R>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, Value?>, at queue: DispatchQueue? = nil) -> AnyObserver where R: AnyObject {
        let transform: (Value) -> Value? = { $0 as Value? }
        return bind(to: receiver, receiverKeyPath, at: queue, transform: transform)
    }
}

extension Observeable where Value: Equatable {    
    // 2 -> 0
    @discardableResult
    public func bindDiff<R>(to receiver: R, at queue: DispatchQueue? = nil, handler: @escaping (R, ObservedChange<Value>) -> ()) -> AnyObserver where R: AnyObject {
        return bind(to: receiver, at: queue) { receiver, change in
            if change.oldValue != change.newValue {
                handler(receiver, change)
            }
        }
    }
    
    // 3 -> 2
    @discardableResult
    public func bindDiff<R, V>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, V>, at queue: DispatchQueue? = nil, transform: @escaping (Value) -> V) -> AnyObserver where R: AnyObject {
        return bindDiff(to: receiver, at: queue) { receiver, change in
            receiver[keyPath: receiverKeyPath] = transform(change.newValue)
        }
    }
    
    // -> 3
    @discardableResult
    public func bindDiff<R>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, Value>, at queue: DispatchQueue? = nil) -> AnyObserver where R: AnyObject {
        let transform: (Value) -> Value = { $0 }
        return bindDiff(to: receiver, receiverKeyPath, at: queue, transform: transform)
    }
    
    // -> 3
    @discardableResult
    public func bindDiff<R>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, Value?>, at queue: DispatchQueue? = nil) -> AnyObserver where R: AnyObject {
        let transform: (Value) -> Value? = { $0 as Value? }
        return bindDiff(to: receiver, receiverKeyPath, at: queue, transform: transform)
    }
}

