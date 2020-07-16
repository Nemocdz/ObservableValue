//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/16.
//

import Foundation

extension Observeable {
    @discardableResult
    public func bind<R>(to receiver: R, at queue: DispatchQueue? = nil, handler: @escaping (R, ObservedChange<Value>) -> ()) -> AnyObserver where R: AnyObject {
        let observer = addObserver(at: queue) { [weak receiver] change in
            guard let receiver = receiver else { return }
            handler(receiver, change)
        }
        observer.store(in: receiver)
        return observer
    }
    
    @discardableResult
    public func bind<R, V>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, V>, at queue: DispatchQueue? = nil, transform: @escaping (Value) -> V) -> AnyObserver where R: AnyObject {
        return bind(to: receiver, at: queue) { receiver, change in
            receiver[keyPath: receiverKeyPath] = transform(change.newValue)
        }
    }
    
    @discardableResult
    public func bind<R>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, Value>, at queue: DispatchQueue? = nil) -> AnyObserver where R: AnyObject {
        let transform: (Value) -> Value = { $0 }
        return bind(to: receiver, receiverKeyPath, transform: transform)
    }
    
    @discardableResult
    public func bind<R>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, Value?>, at queue: DispatchQueue? = nil) -> AnyObserver where R: AnyObject {
        let transform: (Value) -> Value? = { $0 as Value? }
        return bind(to: receiver, receiverKeyPath, transform: transform)
    }
}
