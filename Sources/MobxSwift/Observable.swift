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
            notifyAll(oldValue: oldValue, newValue: newValue)
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
    
    public func update(_ newValue: Value) {
        lock.lock()
        defer { lock.unlock() }

        value = newValue
    }
    
    private func notifyAll(oldValue: Value, newValue: Value) {
        observers = observers.filter { $0.isObserving($0) }
        observers.forEach { $0.notify(ObservedChange(oldValue, newValue)) }
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
    public func addObserver<O>(for object: O, at queue: DispatchQueue? = nil, handler: @escaping (O, ObservedChange<Value>) -> ()) -> AnyObserver where O: AnyObject {
        let observer = addObserver(at: queue) { [weak object] change in
            guard let object = object else { return }
            handler(object, change)
        }
        observer.store(in: object)
        return observer
    }
        
    @discardableResult
    public func addObserver(at queue: DispatchQueue? = nil, handler: @escaping (ObservedChange<Value>) -> ()) -> AnyObserver {
        lock.lock()
        defer { lock.unlock() }
        
        func handle(oldValue: Value? = nil, newValue: Value) {
            if let queue = queue {
                queue.async {
                    handler(ObservedChange(oldValue, newValue))
                }
            } else {
                handler(ObservedChange(oldValue, newValue))
            }
        }
        
        handle(newValue: value)
        
        let observer = Observer<Value> { oldValue, newValue in
            handle(oldValue: oldValue, newValue: newValue)
        }
        
        observers.insert(observer)
        
        return AnyObserver(removeHandler: { [weak self, weak observer] in
            guard let self = self, let observer = observer else { return false }
            return self.remove(observer)
        }, storeInHandler: { [weak observer] retain, object in
            guard let observer = observer else { return }
            observer.retainObject = retain
            observer.isObserving = { [weak object, unowned retain] observer in
                if object == nil {
                    observer.retainObject = nil
                }
                return retain.storeOption == .object ? object != nil : true
            }
        })
    }
    
    public func removeObservers() {
        lock.lock()
        defer { lock.unlock() }
        
        observers.removeAll()
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

