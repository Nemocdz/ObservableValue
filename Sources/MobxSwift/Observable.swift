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
    private var uniqueID = (0...).makeIterator()
    private var lock = NSRecursiveLock()
    
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
    public func addObserver<Object>(for object: Object, at queue: DispatchQueue? = nil, handler: @escaping(Object, Value?, Value) -> ()) -> AnyObserver where Object: AnyObject {
        lock.lock()
        defer { lock.unlock() }
        
        func handle(object: Object, oldValue: Value? = nil, newValue: Value) {
            if let queue = queue {
                queue.async {
                    handler(object, oldValue, newValue)
                }
            } else {
                handler(object, oldValue, newValue)
            }
        }
        
        handle(object: object, newValue: value)
        
        let observer = Observer<Value>(id: uniqueID.next()!) { [weak object] oldValue, newValue in
            guard let object = object else {
                return false
            }
            
            handle(object: object, oldValue: oldValue, newValue: newValue)
            return true
        }
        
        observers.insert(observer)
        
        return AnyObserver {
            self.remove(observer)
        }
    }
    
    public func update(_ newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
    
    @discardableResult
    private func remove(_ observer: Observer<Value>) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return observers.remove(observer) != nil
    }
}

extension Observeable {
    /// key
    @discardableResult
    public func bind<Receiver, ReceiverValue>(to receiver: Receiver, _ receiverKeyPath: ReferenceWritableKeyPath<Receiver, ReceiverValue>, at queue: DispatchQueue? = nil, transform: @escaping (Value) -> ReceiverValue) -> AnyObserver where Receiver: AnyObject{
        return addObserver(for: receiver, at: queue) { receiver, oldValue, newValue in
            receiver[keyPath: receiverKeyPath] = transform(newValue)
        }
    }
    
    /// convience
    @discardableResult
    public func bind<Receiver>(to receiver: Receiver, _ receiverKeyPath: ReferenceWritableKeyPath<Receiver, Value>, at queue: DispatchQueue? = nil) -> AnyObserver where Receiver: AnyObject{
        let transform: (Value) -> Value = { $0 }
        return bind(to: receiver, receiverKeyPath, transform: transform)
    }
    
    @discardableResult
    public func bind<Receiver>(to receiver: Receiver, _ receiverKeyPath: ReferenceWritableKeyPath<Receiver, Value?>, at queue: DispatchQueue? = nil) -> AnyObserver where Receiver: AnyObject {
        let transform: (Value) -> Value? = { $0 as Value? }
        return bind(to: receiver, receiverKeyPath, transform: transform)
    }
}

