//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/10.
//

import Foundation

public final class Observeable<Value> {
    typealias NotifyPredicate = ((ObservedChange<Value>) -> Bool)
    
    private var observers: Set<Observer<Value>> = []
    private let lock = NSRecursiveLock()
    private let dispatchKey = DispatchSpecificKey<Void>()
    private var notifyPredicates: [NotifyPredicate] = []
    
    private var queue: DispatchQueue = .main {
        willSet { queue.setSpecific(key: dispatchKey, value: nil) }
        didSet { queue.setSpecific(key: dispatchKey, value: ()) }
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
    
    @discardableResult private func remove(_ observer: Observer<Value>) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return observers.remove(observer) != nil
    }
    
    private func canNotify(_ change: ObservedChange<Value>) -> Bool {
        return notifyPredicates.filter{ $0(change) }.count == notifyPredicates.count
    }
}

extension Observeable {
    
    /// 设置新值
    /// - Parameter newValue: 新值
    public func update(_ newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        
        value = newValue
    }
    
    /// 增加监听
    /// - Parameter handler: 执行事件
    /// - Returns: 可移除监听者
    @discardableResult public func addObserver(handler: @escaping (ObservedChange<Value>) -> ()) -> Disposable {
        lock.lock()
        defer { lock.unlock() }
        
        func handle(_ change: ObservedChange<Value>) {
            guard canNotify(change) else { return }
            let isAsync = DispatchQueue.getSpecific(key: self.dispatchKey) == nil
            if isAsync {
                queue.async { handler(change) }
            } else {
                handler(change)
            }
        }
        
        let observer = Observer<Value> { change in
            handle(change)
        }
        
        observers.insert(observer)
        
        return Disposable(addHandler: {
            let bag = $0
            observer.isObserving = { [weak bag] in
                bag != nil
            }
        }, removeHandler: {
            self.remove(observer)
        }).unowned()
    }
    
    /// 移除所有监听者
    public func removeObservers() {
        lock.lock()
        defer { lock.unlock() }
        
        observers.removeAll()
    }
    
    /// 改变执行事件的队列
    /// - Parameter queue: 目标队列
    /// - Returns: self
    public func dispatch(on queue: DispatchQueue) -> Observeable<Value> {
        self.queue = queue
        return self
    }
}

extension Observeable {
    
    /// 增加忽略改变的情况
    /// - Parameter predicate: 忽略情况
    /// - Returns: self
    public func drop(while predicate: @escaping (ObservedChange<Value>) -> Bool) -> Observeable<Value> {
        notifyPredicates.append { !predicate($0) }
        return self
    }
}

extension Observeable where Value: Equatable {
    
    /// 忽略改变新旧值相等的情况
    /// - Returns: self
    public func dropSame() -> Observeable<Value> {
        return drop(while: ==)
    }
}

extension Observeable {
    public func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Observeable<NewValue> {
        let observable = Observeable<NewValue>(transform(value))
        addObserver {
            observable.update(transform($0.newValue))
        }.add(to: observable)
        return observable
    }
}

extension Observeable where Value: ObservableOptionalValue {
    public func dropNil(value: Value.Wrapped) -> Observeable<Value.Wrapped> {
        let observable = Observeable<Value.Wrapped>(value)
        addObserver {
            guard !$0.newValue.isNil else { return }
            observable.update($0.newValue.wrapped)
        }.add(to: observable)
        return observable
    }
}
