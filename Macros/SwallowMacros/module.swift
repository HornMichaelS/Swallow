//
// Copyright (c) Vatsal Manot
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
public struct module: CompilerPlugin {
    public static var domain: String {
        "com.vmanot.SwallowMacros"
    }
    
    public let providingMacros: [Macro.Type] = [
        AssociatedObjectMacro.self,
        AddCaseBooleanMacro.self,
        GenerateDuplicateMacro.self,
        DeclarationScopeMacro.self,
        HashableMacro.self,
        KeyAutogeneratedMacro.self,
        KeysAutogeneratedMacro.self,
        ManagedActorMacro.self,
        ManagedActorMethodMacro.self,
        MemoizedPropertyMacro.self,
        OnceMacro.self,
        OptionSetMacro.self,
        RuntimeConversionMacro.self,
        RuntimeDiscoverableMacro.self,
        _StaticProtocolMember.self,
        SingletonMacro.self,
        TryMacro.self,
        TryAwaitMacro.self,
        _InternalTestMacro.self
    ]
    
    public init() {
        
    }
}
