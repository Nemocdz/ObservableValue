//
//  File.swift
//
//
//  Created by Nemo on 2020/7/10.
//

import Foundation

final class Observer<Value> {
    typealias ReceiveHandler = (ObservedChange<Value>) -> ()

    let receive: ReceiveHandler
    var isObserving: () -> Bool

    init(receiveHandler: @escaping ReceiveHandler) {
        receive = receiveHandler
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
