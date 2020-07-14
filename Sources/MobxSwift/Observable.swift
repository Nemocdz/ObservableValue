//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/10.
//

import Foundation

@propertyWrapper
public final class Observeable<Value> {
    private var observers: Set<Observer<Value>> = []
    private let lock = NSRecursiveLock()
    
    public private(set) var value: Value {
        didSet {
            let newValue = value
            observers = observers.filter{ $0.notifyHandler(oldValue, newValue) }
        }
    }
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public convenience init(wrappedValue: Value) {
        self.init(wrappedValue)
    }
    
    public var projectedValue: Observeable<Value> {
        return self
    }
    
    public var wrappedValue: Value {
        get {
            return value
        }
        set {
            update(newValue)
        }
    }
    
    @discardableResult
    public func addObserver(at queue: DispatchQueue? = nil, handler: @escaping (ObservedChange<Value>) -> ()) -> AnyObserver {
        return addObserver(for: self, at: queue) { _, change in
            handler(change)
        }
    }
    
    @discardableResult
    public func addObserver<O>(for object: O, at queue: DispatchQueue? = nil, handler: @escaping (O, ObservedChange<Value>) -> ()) -> AnyObserver where O: AnyObject {
        lock.lock()
        defer { lock.unlock() }
        
        func handle(object: O, oldValue: Value? = nil, newValue: Value) {
            if let queue = queue {
                queue.async {
                    handler(object, ObservedChange(oldValue, newValue))
                }
            } else {
                handler(object, ObservedChange(oldValue, newValue))
            }
        }
        
        handle(object: object, newValue: value)
        
        let observer = Observer<Value> { [weak object] oldValue, newValue in
            guard let object = object else { return false }
            handle(object: object, oldValue: oldValue, newValue: newValue)
            return true
        }
        
        observers.insert(observer)
        
        return AnyObserver { [weak self, weak observer] in
            guard let self = self, let observer = observer else { return false }
            self.remove(observer)
            return true
        }
    }
    
    public func update(_ newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        
        value = newValue
    }
    
    public func removeObservers() {
        lock.lock()
        defer { lock.unlock() }
        
        observers.removeAll()
    }
    
    @discardableResult
    private func remove(_ observer: Observer<Value>) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return observers.remove(observer) != nil
    }
}

extension Observeable {
    @discardableResult
    public func bind<R, V>(to receiver: R, _ receiverKeyPath: ReferenceWritableKeyPath<R, V>, at queue: DispatchQueue? = nil, transform: @escaping (Value) -> V) -> AnyObserver where R: AnyObject {
        return addObserver(for: receiver, at: queue) { receiver, change in
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

