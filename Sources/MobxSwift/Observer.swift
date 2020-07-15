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
    private var objectIsRemove: (() -> Bool)
    private let storeInObjectHandler: (AnyObserver) -> ()
    
    init(removeHandler: @escaping RemoveHandler, storeInObjectHandler: @escaping (AnyObserver) -> ()) {
        self.removeHandler = removeHandler
        self.storeInObjectHandler = storeInObjectHandler
        self.objectIsRemove = {
            return true
        }
    }
    
    @discardableResult
    public func store(in object: AnyObject?) -> AnyObserver {
        objectIsRemove = { [weak object] in
            return object == nil
        }
        storeInObjectHandler(self)
        return self
    }
    
    func shouldRemove() -> Bool {
        return objectIsRemove()
    }
    
    @discardableResult
    public func store<C>(in collection: inout C) -> AnyObserver where C : RangeReplaceableCollection, C.Element == AnyObserver {
        collection.append(self)
        objectIsRemove = {
            return true
        }
        return self
    }
    
    @discardableResult
    public func remove() -> Bool {
        return removeHandler()
    }
    
    deinit {
        remove()
    }
}

final class Observer<Value> {
    typealias NotifyHandler = (Value, Value) -> ()
    
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
