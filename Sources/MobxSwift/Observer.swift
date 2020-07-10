//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/10.
//

import Foundation

public final class Observer<Value> {
    let handler: (Value, Value) -> Bool
    private let id: Int
    
    init(id: Int, _ handler: @escaping (Value, Value) -> Bool) {
        self.id = id
        self.handler = handler
    }
}

extension Observer: Hashable {
    public static func == (lhs: Observer<Value>, rhs: Observer<Value>) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
