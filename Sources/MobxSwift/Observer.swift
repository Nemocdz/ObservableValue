//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/10.
//

import Foundation

public final class AnyObserver {
    typealias RemoveHandler = () -> Bool
    
    private let removeHandler: RemoveHandler
    
    init(removeHandler: @escaping RemoveHandler) {
        self.removeHandler = removeHandler
    }
    
    public func remove() -> Bool {
        return removeHandler()
    }
}

final class Observer<Value> {
    typealias NotifyHandler = (Value, Value) -> Bool
    
    private let id: Int
    let notifyHandler: NotifyHandler
    
    init(id: Int, notifyHandler: @escaping NotifyHandler) {
        self.id = id
        self.notifyHandler = notifyHandler
    }
    
    deinit {
        print("ass")
    }
}

extension Observer: Hashable {
    static func == (lhs: Observer<Value>, rhs: Observer<Value>) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
