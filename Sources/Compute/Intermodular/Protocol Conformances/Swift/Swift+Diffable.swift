//
// Copyright (c) Vatsal Manot
//

import Swallow

extension Array: Diffable where Element: Equatable {
    public typealias Difference = CollectionDifference<Element>
}

extension ArraySlice: Diffable where Element: Equatable {
    public typealias Difference = CollectionDifference<Element>
}

extension ContiguousArray: Diffable where Element: Equatable {
    public typealias Difference = CollectionDifference<Element>
}

extension CollectionOfOne: Diffable where Element: Equatable {
    public struct Difference: Equatable {
        public enum Change: Equatable {
            case update(from: Element, to: Element)
            
            public var oldValue: Element {
                switch self {
                    case .update(let oldValue, _):
                        return oldValue
                }
            }
            
            public var newValue: Element {
                switch self {
                    case .update(_, let newValue):
                        return newValue
                }
            }
        }
        
        public let update: Change?
        
        public init(update: Change?) {
            self.update = update
        }
        
        public func map<T>(
            _ transform: (Element) throws -> T
        ) rethrows -> CollectionOfOne<T>.Difference {
            guard let update = update else {
                return CollectionOfOne<T>.Difference(update: nil)
            }
            
            switch update {
                case .update(let oldValue, let newValue):
                    return try CollectionOfOne<T>.Difference(
                        update: .update(from: transform(oldValue), to: transform(newValue))
                    )
            }
        }
    }
    
    public func difference(from other: Self) -> Difference {
        if value != other.value {
            return Difference(update: .update(from: other.value, to: value))
        } else {
            return Difference(update: nil)
        }
    }
    
    public func applying(_ difference: Difference) -> Self? {
        guard let update = difference.update else {
            return self
        }
        
        switch update {
            case .update(let oldElement, let newElement):
                guard value == oldElement else {
                    return nil
                }
                
                return .init(newElement)
        }
    }
    
    public mutating func applyUnconditionally(_ difference: Difference) {
        TODO.here(.test)
        
        guard let update = difference.update else {
            return
        }
        
        switch update {
            case .update(_, let newValue):
                value = newValue
        }
    }
}

public struct DictionaryDifference<Key: Hashable, Value>: Sequence {
    public enum Change {
        case insert(key: Key, value: Value)
        case update(key: Key, value: Value)
        case remove(key: Key)
        
        var key: Key {
            switch self {
                case .insert(let key, _):
                    return key
                case .update(let key, _):
                    return key
                case .remove(let key):
                    return key
            }
        }
        
        var value: Value? {
            switch self {
                case .insert(_, let value):
                    return value
                case .update(_, let value):
                    return value
                case .remove:
                    return nil
            }
        }
    }
    
    public var insertions: [Change]
    public var updates: [Change]
    public var removals: [Change]
    
    public var isEmpty: Bool {
        insertions.isEmpty && updates.isEmpty && removals.isEmpty
    }
    
    public init(
        insertions: [Change],
        updates: [Change],
        removals: [Change]
    ) {
        self.insertions = insertions
        self.updates = updates
        self.removals = removals
    }
    
    public mutating func merge(_ change: Change) {
        insertions.removeAll(where: { $0.key == change.key })
        updates.removeAll(where: { $0.key == change.key })
        removals.removeAll(where: { $0.key == change.key })
        
        switch change {
            case .insert:
                insertions.append(change)
            case .update:
                updates.append(change)
            case .remove:
                removals.append(change)
        }
    }
    
    public subscript(_ key: Key) -> Value? {
        get {
            if removals.contains(where: { $0.key == key }) {
                return nil
            } else {
                return insertions.join(updates).first(where: { $0.key == key })?.value
            }
        } set {
            if let newValue = newValue {
                merge(.update(key: key, value: newValue))
            } else {
                merge(.remove(key: key))
            }
        }
    }
    
    public func makeIterator() -> AnyIterator<Change> {
        return .init((insertions + updates + removals).makeIterator())
    }
}

extension Dictionary: Diffable where Value: Equatable {
    public typealias Difference = DictionaryDifference<Key, Value>
    
    public func difference(from other: Dictionary) -> Difference {
        var insertions: [Difference.Change] = []
        var updates: [Difference.Change] = []
        var removals: [Difference.Change] = []
        
        var checkedPairs = self
        
        for (otherKey, otherValue) in other {
            if let value = checkedPairs[otherKey] {
                if value != otherValue {
                    updates += .update(key: otherKey, value: value)
                }
            } else {
                removals += .remove(key: otherKey)
            }
            
            checkedPairs.removeValue(forKey: otherKey)
        }
        
        insertions = checkedPairs.keysAndValues.map({ .insert(key: $0.key, value: $0.value) })
        
        return .init(
            insertions: insertions,
            updates: updates,
            removals: removals
        )
    }
    
    public mutating func applyUnconditionally(_ difference: Difference) {
        for change in difference {
            switch change {
                case let .insert(key, value):
                    assert(index(forKey: key) == nil)
                    self[key] = value
                case let .update(key, value):
                    assert(index(forKey: key) != nil)
                    self[key] = value
                case let .remove(key):
                    assert(index(forKey: key) != nil)
                    removeValue(forKey: key)
            }
        }
    }
    
    public func applying(_ difference: Difference) -> Dictionary? {
        return build(self, with: { $0.applyUnconditionally($1) }, difference)
    }
}

extension Result: Diffable where Success: Diffable {
    public typealias Difference = Result<Success.Difference, Failure>
    
    public func difference(from other: Result) -> Result<Success.Difference, Failure> {
        switch (self, other) {
            case let (.success(x), .success(y)):
                return .success(x.difference(from: y))
            case let (.failure(x), _):
                return .failure(x)
            case let (_, .failure(y)):
                return .failure(y)
        }
    }
    
    public func applying(_ difference: Difference) -> Result? {
        switch (self, difference) {
            case let (.success(x), .success(y)):
                return x.applying(y).map(Result.success)
            case let (.failure(x), _):
                return .failure(x)
            case let (_, .failure(y)):
                return .failure(y)
        }
    }
    
    public mutating func applyUnconditionally(_ difference: Difference) throws {
        switch (self, difference) {
            case (var .success(x), let .success(y)):
                try x.applyUnconditionally(y)
                self = .success(x)
            case let (.failure(x), _):
                self = .failure(x)
            case let (_, .failure(y)):
                self = .failure(y)
        }
    }
}

extension Set: Diffable {
    public struct Difference: Hashable {
        public var inserted: Set
        public var removed: Set
        
        public init(inserted: Set, removed: Set) {
            self.inserted = inserted
            self.removed = removed
        }
        
        public func map<T>(
            _ transform: (Element) throws -> T
        ) rethrows -> Set<T>.Difference {
            try .init(inserted: Set<T>(inserted.map(transform)), removed: Set<T>(inserted.map(transform)))
        }
    }
    
    public func difference(from other: Self) -> Difference {
        return Difference(
            inserted: subtracting(other),
            removed: other.subtracting(self)
        )
    }
    
    public func applying(_ difference: Difference) -> Self? {
        var result = self
        
        result.applyUnconditionally(difference) // FIXME
        
        return result
    }
    
    public mutating func applyUnconditionally(_ difference: Difference) {
        formUnion(difference.inserted)
        subtract(difference.removed)
    }
}

extension Slice: Diffable where Base: BidirectionalCollection & RangeReplaceableCollection, Element: Equatable {
    public typealias Difference = CollectionDifference<Element>
}

extension String: Diffable {
    public typealias Difference = CollectionDifference<Element>
}

extension Substring: Diffable {
    public typealias Difference = CollectionDifference<Element>
}
