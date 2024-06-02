//
// Copyright (c) Vatsal Manot
//

import Swift

extension _StaticSwift {
    /// A (typically `enum`) type that serves a namespace (in lieu of an actual namespace language feature).
    public protocol Namespace {
        
    }
    
    public protocol TypeIterableNamespace: _StaticSwift.Namespace {
        associatedtype _NamespaceChildType: _StaticSwift.TypeExpression = _StaticSwift.OpaqueExistentialTypeExpression
        
        @ArrayBuilder
        static var _allNamespaceTypes: [_NamespaceChildType._Metatype] { get }
    }
}

extension _StaticSwift.TypeIterableNamespace {
    @_spi(Internal)
    public static var _opaque_allNamespaceTypes: [Any.Type] {
        _allNamespaceTypes.map({ $0 as! Any.Type })
    }
}

// MARK: - Deprecated

@available(*, deprecated)
public typealias _StaticNamespaceType = _StaticSwift.Namespace
