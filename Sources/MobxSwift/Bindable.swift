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
    // 0
    @discardableResult
    public func bind<R>(to receiver: R, handler: @escaping (R, ObservedChange<Value>) -> ()) -> Disposable where R: AnyObject {
        let observer = addObserver { [weak receiver] change in
            guard let receiver = receiver else { return }
            handler(receiver, change)
        }
        observer.add(to: receiver)
        return observer
    }
    
    // -> 0
    @discardableResult
    public func bind<R>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, Value>) -> Disposable where R: AnyObject {
        return bind(to: receiver) { receiver, change in
            receiver[keyPath: receiverKeyPath] = change.newValue
        }
    }
    
    // -> 0
    @discardableResult
    public func bind<R>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, Value?>) -> Disposable where R: AnyObject {
        return bind(to: receiver) { receiver, change in
            receiver[keyPath: receiverKeyPath] = change.newValue as Value?
        }
    }
}
