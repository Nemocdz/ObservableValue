//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/10.
//

import Foundation

public final class AnyObserver {
    typealias RemoveHandler = () -> Bool
    typealias StoreInHandler = ((AnyObserver, AnyObject?) -> ())
    
    private let remove: RemoveHandler
    private let storeIn: StoreInHandler
    var storeOption: StoreOptions = []
    
    init(removeHandler: @escaping RemoveHandler, storeInHandler: @escaping StoreInHandler) {
        remove = removeHandler
        storeIn = storeInHandler
    }
    
    public func store(in object: AnyObject?) {
        storeIn(self, object)
        storeOption.insert(.object)
    }
    
    public func store<C>(in collection: inout C) where C : RangeReplaceableCollection, C.Element == AnyObserver {
        collection.append(self)
        storeOption.insert(.collection)
    }
    
    @discardableResult
    public func stop() -> Bool {
        return remove()
    }
    
    deinit {
        stop()
    }
}

extension AnyObserver {
    struct StoreOptions: OptionSet {
        let rawValue: Int
        
        static let object = StoreOptions(rawValue: 1 << 0)
        static let collection = StoreOptions(rawValue: 1 << 1)
    }
}


final class Observer<Value> {
    typealias NotifyHandler = (ObservedChange<Value>) -> ()
    
    let notify: NotifyHandler
    
    var retainObject: AnyObject?
    
    var isObserving: (Observer<Value>) -> Bool
    
    init(notifyHandler: @escaping NotifyHandler) {
        self.notify = notifyHandler
        self.isObserving = { _ in true }
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
