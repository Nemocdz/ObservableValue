//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/10.
//

import Foundation

public final class AnyObserver {
    private let handler: () -> ()
    
    init(_ handler: @escaping () -> ()) {
        self.handler = handler
    }
    
    public func remove() {
        handler()
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
}

extension Observer: Hashable {
    static func == (lhs: Observer<Value>, rhs: Observer<Value>) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
