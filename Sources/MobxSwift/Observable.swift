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
    private var uniqueId = (0...).makeIterator()
    private var lock = NSRecursiveLock()
    
    private var value: Value {
        didSet {
            lock.lock()
            defer { lock.unlock() }
            let newValue = value
            observers = observers.filter{ $0.handler(oldValue, newValue) }
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
            value = newValue
        }
    }
    
    @discardableResult
    public func addObserver<Object>(for object: Object, at queue: DispatchQueue? = nil, handler: @escaping(Object, Value?, Value) -> ()) -> Observer<Value> where Object: AnyObject {
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
        
        let observer = Observer<Value>(id: uniqueId.next()!) { [weak object] oldValue, newValue in
            guard let object = object else {
                return false
            }
            
            handle(object: object, oldValue: oldValue, newValue: newValue)
            return true
        }
        
        observers.insert(observer)
        return observer
    }
    
    @discardableResult
    public func remove(_ observer: Observer<Value>) -> Bool {
        observers.remove(observer) != nil
    }
}

extension Observeable {
    public final class Binding {
        let handler: () -> ()
        
        init(_ handler: @escaping () -> ()) {
            self.handler = handler
        }
    
        deinit {
            handler()
        }
        
        public func unbind() {
            handler()
        }
    }
    
    /// key
    @discardableResult
    public func bind<Receiver, ReceiverValue>(to receiver: Receiver, _ receiverKeyPath: ReferenceWritableKeyPath<Receiver, ReceiverValue>, at queue: DispatchQueue? = nil, transform: @escaping (Value) -> ReceiverValue) -> Binding where Receiver: AnyObject{
        let observer = addObserver(for: receiver, at: queue) { receiver, oldValue, newValue in
            receiver[keyPath: receiverKeyPath] = transform(newValue)
        }
        
        return Binding {
            self.remove(observer)
        }
    }
    
    /// convience
    @discardableResult
    public func bind<Receiver>(to receiver: Receiver, _ receiverKeyPath: ReferenceWritableKeyPath<Receiver, Value>, at queue: DispatchQueue? = nil) -> Binding where Receiver: AnyObject{
        let transform: (Value) -> Value = { $0 }
        return bind(to: receiver, receiverKeyPath, transform: transform)
    }
    
    @discardableResult
    public func bind<Receiver>(to receiver: Receiver, _ receiverKeyPath: ReferenceWritableKeyPath<Receiver, Value?>, at queue: DispatchQueue? = nil) -> Binding where Receiver: AnyObject {
        let transform: (Value) -> Value? = { $0 as Value? }
        return bind(to: receiver, receiverKeyPath, transform: transform)
    }
}

