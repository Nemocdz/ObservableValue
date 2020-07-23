//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/10.
//

import Foundation

final class Observer<Value> {
    typealias NotifyHandler = (ObservedChange<Value>) -> ()
    
    let notify: NotifyHandler
    var isObserving: () -> Bool
    
    init(notifyHandler: @escaping NotifyHandler) {
        notify = notifyHandler
        isObserving = { true }
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
