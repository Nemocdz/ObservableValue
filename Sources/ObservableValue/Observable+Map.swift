//
//  File.swift
//  
//
//  Created by Nemo on 2021/6/14.
//

import Foundation

public extension Observable {
    
    /// 返回新类型的可观察者
    /// - Parameter transform: 转换
    /// - Returns: 新的可观察者
    func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Observable<NewValue> {
        let observable = Observable<NewValue>(transform(value))
        addObserver {
            observable.update(transform($0.newValue))
        }.add(to: observable)
        return observable
    }
}
