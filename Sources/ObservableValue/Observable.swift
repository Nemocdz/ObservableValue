//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/10.
//

import Foundation

public final class Observable<Value> {
    typealias ChangePredicate = ((ObservedChange<Value>) -> Bool)
    
    private var observers: Set<Observer<Value>> = []
    private let lock = NSRecursiveLock()
    private let queueKey = DispatchSpecificKey<Void>()
    private var changePredicates: [ChangePredicate] = []
    
    private var receiveQueue: DispatchQueue = .main {
        willSet { receiveQueue.setSpecific(key: queueKey, value: nil) }
        didSet { receiveQueue.setSpecific(key: queueKey, value: ()) }
    }
    
    public private(set) var value: Value {
        didSet {
            let newValue = value
            receive(change: (oldValue, newValue))
        }
    }
    
    public init(_ value: Value) {
        self.value = value
        receiveQueue.setSpecific(key: queueKey, value: ())
    }
    
    deinit {
        receiveQueue.setSpecific(key: queueKey, value: nil)
    }
    
    private func receive(change: ObservedChange<Value>) {
        observers = observers.filter { $0.isObserving() }
        observers.forEach { $0.receive(change) }
    }
    
    @discardableResult private func remove(_ observer: Observer<Value>) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return observers.remove(observer) != nil
    }
    
    private func canReceive(_ change: ObservedChange<Value>) -> Bool {
        return changePredicates.filter{ $0(change) }.count == changePredicates.count
    }
}

extension Observable {
    
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
        
        func receive(_ change: ObservedChange<Value>) {
            guard canReceive(change) else { return }
            let isAsync = DispatchQueue.getSpecific(key: queueKey) == nil
            if isAsync {
                receiveQueue.async { handler(change) }
            } else {
                handler(change)
            }
        }
        
        let observer = Observer<Value> { change in
            receive(change)
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
    public func dispatch(on queue: DispatchQueue) -> Observable<Value> {
        receiveQueue = queue
        return self
    }
}

extension Observable {
    
    /// 增加忽略改变的情况
    /// - Parameter predicate: 忽略情况
    /// - Returns: self
    public func drop(while predicate: @escaping (ObservedChange<Value>) -> Bool) -> Observable<Value> {
        changePredicates.append { !predicate($0) }
        return self
    }
}

extension Observable where Value: Equatable {
    
    /// 忽略改变新旧值相等的情况
    /// - Returns: self
    public func dropSame() -> Observable<Value> {
        return drop(while: ==)
    }
}

extension Observable {
    public func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Observable<NewValue> {
        let observable = Observable<NewValue>(transform(value))
        addObserver {
            observable.update(transform($0.newValue))
        }.add(to: observable)
        return observable
    }
}

extension Observable where Value: ObservableOptionalValue {
    public func dropNil(value: Value.Wrapped) -> Observable<Value.Wrapped> {
        let observable = Observable<Value.Wrapped>(value)
        addObserver {
            guard !$0.newValue.isNil else { return }
            observable.update($0.newValue.wrapped)
        }.add(to: observable)
        return observable
    }
}
