//
//  File.swift
//
//
//  Created by Nemo on 2021/6/14.
//

import Foundation

public extension Observable {
    /// 增加忽略改变的情况
    /// - Parameter predicate: 是否忽略
    /// - Returns: self
    func drop(while predicate: @escaping (ObservedChange<Value>) -> Bool) -> Observable<Value> {
        let observable = Observable<Value>(value)
        addObserver {
            guard !predicate($0) else { return }
            observable.update($0.newValue)
        }.add(to: observable)
        return observable
    }
}

public extension Observable where Value: Equatable {
    /// 忽略改变新旧值相等的情况
    /// - Returns: self
    func dropSame() -> Observable<Value> {
        return drop(while: ==)
    }
}

public extension Observable where Value: ObservableOptional {
    /// 忽略 nil 的情况
    /// - Parameter value: 初始化值
    /// - Returns: 新的可观察者
    func dropNil(value: Value.Wrapped) -> Observable<Value.Wrapped> {
        let observable = Observable<Value.Wrapped>(value)
        addObserver {
            guard !$0.newValue._isNil else { return }
            observable.update($0.newValue._wrapped)
        }.add(to: observable)
        return observable
    }
}
