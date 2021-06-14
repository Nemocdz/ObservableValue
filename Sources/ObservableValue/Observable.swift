//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/10.
//

import Foundation

public typealias ObservedChange<Value> = (oldValue: Value, newValue: Value)

public final class Observable<Value> {
    private var observers: Set<Observer<Value>> = []
    private let lock = NSRecursiveLock()
    
    public private(set) var value: Value {
        didSet { receive(change: (oldValue, value)) }
    }
    
    public init(_ value: Value) {
        self.value = value
    }
}


// MARK: - Public
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

// MARK: - Private
extension Observable {
    private func receive(change: ObservedChange<Value>) {
        observers
            .filter { $0.isObserving() }
            .forEach { $0.receive(change) }
    }
    
    @discardableResult
    private func remove(_ observer: Observer<Value>) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return observers.remove(observer) != nil
    }
}


