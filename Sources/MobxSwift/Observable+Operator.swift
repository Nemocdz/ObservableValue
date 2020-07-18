//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/19.
//

import Foundation

extension Observeable {
    public func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Observeable<NewValue> {
        return Observeable<NewValue>(transform(value))
    }
    
    public func dispatch(on queue: DispatchQueue) -> Observeable<Value> {
        let o = Observeable(value)
        o.queue = queue
        return o
    }
    
    public func drop(while predicate: @escaping (ObservedChange<Value>) -> Bool) -> Observeable<Value> {
        let o = Observeable(value)
        o.notifyPredicate = predicate
        return o
    }
}

extension Observeable where Value: Equatable {
    public func dropSame() -> Observeable<Value> {
        return drop(while: ==)
    }
}
