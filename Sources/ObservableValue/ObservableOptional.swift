//
//  File.swift
//
//
//  Created by Nemo on 2020/7/23.
//

import Foundation

public protocol ObservableOptional {
    associatedtype Wrapped

    var _wrapped: Wrapped { get }
    var _isNil: Bool { get }
}

extension Optional: ObservableOptional {
    public var _wrapped: Wrapped { unsafelyUnwrapped }
    public var _isNil: Bool { self == nil }
}
