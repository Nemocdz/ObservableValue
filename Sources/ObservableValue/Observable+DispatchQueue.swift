//
//  File.swift
//
//
//  Created by Nemo on 2021/6/14.
//

import Foundation

public extension Observable {
    /// 改变执行事件的队列
    /// - Parameter queue: 目标队列
    /// - Returns: self
    func dispatch(on queue: DispatchQueue) -> Observable<Value> {
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
