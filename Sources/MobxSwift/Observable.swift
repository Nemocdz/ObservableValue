//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/10.
//

import Foundation
import Combine

public final class Observeable<Value> {
    private var observers: Set<Observer<Value>> = []
    private let lock = NSRecursiveLock()
    private let dispatchKey = DispatchSpecificKey<Void>()
    
    typealias NotifyPredicate = ((ObservedChange<Value>) -> Bool)
    var notifyPredicates: [NotifyPredicate] = []
    var queue: DispatchQueue = .main {
        willSet {
            queue.setSpecific(key: dispatchKey, value: nil)
        }
        didSet {
            queue.setSpecific(key: dispatchKey, value: ())
        }
    }
    
    public private(set) var value: Value {
        didSet {
            let newValue = value
            notifyAll(oldValue: oldValue, newValue: newValue)
        }
    }
    
    public init(_ value: Value) {
        self.value = value
        queue.setSpecific(key: dispatchKey, value: ())
    }

    deinit {
        queue.setSpecific(key: dispatchKey, value: nil)
    }
    
    private func notifyAll(oldValue: Value, newValue: Value) {
        observers = observers.filter { $0.isObserving() }
        let change = ObservedChange(oldValue, newValue)
        observers.forEach { $0.notify(change) }
    }
    
    @discardableResult
    private func remove(_ observer: Observer<Value>) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return observers.remove(observer) != nil
    }
    
    private func canNotify(_ change: ObservedChange<Value>) -> Bool {
        return notifyPredicates.filter{ $0(change) }.count == notifyPredicates.count
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
        
        let async = DispatchQueue.getSpecific(key: dispatchKey) == nil
        
        func handle(_ change: ObservedChange<Value>) {
            guard canNotify(change) else { return }
            if async {
                queue.async {
                    handler(change)
                }
            } else {
               handler(change)
            }
        }
    
        handle((oldValue: nil, newValue: value))
        
        let observer = Observer<Value> { change in
            handle(change)
        }
        
        observers.insert(observer)
        
        return AnyObserver(removeHandler: {
            self.remove(observer)
        }, storeInHandler: { object in
            let object = object
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
