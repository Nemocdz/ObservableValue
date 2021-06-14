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
    
    public private(set) var value: Value {
        didSet { receive(change: (oldValue, value)) }
    }
    
    public init(_ value: Value) {
        self.value = value
    }
}

// MARK: - Private
extension Observable {
    private func receive(change: ObservedChange<Value>) {
        observers = observers.filter { $0.isObserving() }
        observers.forEach { $0.receive(change) }
    }
    
    @discardableResult
    private func remove(_ observer: Observer<Value>) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return observers.remove(observer) != nil
    }
}

// MARK: - Pulic
extension Observable {
    
    /// 设置新值
    /// - Parameter newValue: 新值
    public func update(_ newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        
        value = newValue
    }
    
    /// 增加观察者
    /// - Parameter receiveHandler: 接收改变时的处理
    /// - Returns: 可移除观察者
    @discardableResult
    public func addObserver(receiveHandler: @escaping (ObservedChange<Value>) -> ()) -> Disposable {
        lock.lock()
        defer { lock.unlock() }
        
        let observer = Observer<Value> (receiveHandler: receiveHandler)
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
    
    /// 移除所有观察者
    public func removeObservers() {
        lock.lock()
        defer { lock.unlock() }
        
        observers.removeAll()
    }
}

// MARK: - Map
extension Observable {
    
    /// 返回新类型的可观察者
    /// - Parameter transform: 转换
    /// - Returns: 新的可观察者
    public func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Observable<NewValue> {
        let observable = Observable<NewValue>(transform(value))
        addObserver {
            observable.update(transform($0.newValue))
        }.add(to: observable)
        return observable
    }
}

// MARK: - Drop
extension Observable {
    
    /// 增加忽略改变的情况
    /// - Parameter predicate: 是否忽略
    /// - Returns: self
    public func drop(while predicate: @escaping (ObservedChange<Value>) -> Bool) -> Observable<Value> {
        let observable = Observable<Value>(value)
        addObserver {
            guard !predicate($0) else { return }
            observable.update($0.newValue)
        }.add(to: observable)
        return observable
    }
}

extension Observable where Value: Equatable {
    
    /// 忽略改变新旧值相等的情况
    /// - Returns: self
    public func dropSame() -> Observable<Value> {
        return drop(while: ==)
    }
}

extension Observable where Value: ObservableOptional {
    
    /// 忽略 nil 的情况
    /// - Parameter value: 初始化值
    /// - Returns: 新的可观察者
    public func dropNil(value: Value.Wrapped) -> Observable<Value.Wrapped> {
        let observable = Observable<Value.Wrapped>(value)
        addObserver {
            guard !$0.newValue._isNil else { return }
            observable.update($0.newValue._wrapped)
        }.add(to: observable)
        return observable
    }
}


// MARK: - Dispatch
extension Observable {
    
    /// 改变执行事件的队列
    /// - Parameter queue: 目标队列
    /// - Returns: self
    public func dispatch(on queue: DispatchQueue) -> Observable<Value> {
        let key = DispatchSpecificKey<Void>()
        queue.setSpecific(key: key, value: ())
        let observable = Observable<Value>(value)
        addObserver { change in
            if DispatchQueue.getSpecific(key: key) == nil {
                queue.async { observable.update(change.newValue) }
            } else {
                observable.update(change.newValue)
            }
        }.add(to: observable)
        return observable
    }
}
