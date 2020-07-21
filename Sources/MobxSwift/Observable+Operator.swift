//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/19.
//

import Foundation

extension Observeable {
    public func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Observeable<NewValue> {
        let o = Observeable<NewValue>(transform(value))
        addObserver { change in
            guard change.oldValue != nil else { return }
            o.update(transform(change.newValue))
        }
        return o
    }
    
    public func dispatch(on queue: DispatchQueue) -> Observeable<Value> {
        self.queue = queue
        return self
    }
    
    public func drop(while predicate: @escaping (ObservedChange<Value>) -> Bool) -> Observeable<Value> {
        notifyPredicates.append { !predicate($0) }
        return self
    }
    
    public func dropFirst() -> Observeable<Value> {
        return drop(while: { $0.oldValue == nil })
    }
}

extension Observeable where Value: Equatable {
    public func dropSame() -> Observeable<Value> {
        return drop(while: ==)
    }
}
