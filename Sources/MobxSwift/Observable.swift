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
    
    private func notifyAll(oldValue: Value, newValue: Value) {
        observers = observers.filter { $0.isObserving() }
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
    public func update(_ newValue: Value) {
        lock.lock()
        defer { lock.unlock() }

        value = newValue
    }
    
    @discardableResult
    public func addObserver(handler: @escaping (ObservedChange<Value>) -> ()) -> AnyObserver {
        lock.lock()
        defer { lock.unlock() }
        
        handler(ObservedChange(nil, value))
        
        let observer = Observer<Value> { oldValue, newValue in
            handler(ObservedChange(oldValue, newValue))
        }
        
        observers.insert(observer)
        
        return AnyObserver(removeHandler: { [weak self, weak observer] in
            guard let self = self, let observer = observer else { return false }
            return self.remove(observer)
        }, storeInHandler: { [weak observer] object in
            guard let observer = observer else { return }
            observer.isObserving = { [weak object] in
                return object != nil
            }
        })
    }
    
    public func removeObservers() {
        lock.lock()
        defer { lock.unlock() }
        
        observers.removeAll()
    }
}
