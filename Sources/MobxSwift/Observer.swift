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
    
    let notifyHandler: NotifyHandler
    
    init(notifyHandler: @escaping NotifyHandler) {
        self.notifyHandler = notifyHandler
    }
}

extension Observer: Identifiable {
    var id: ObjectIdentifier {
        return ObjectIdentifier(self)
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
