//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension String {
    public init(_staticString string: StaticString) {
        self = string.withUTF8Buffer({ String(decoding: $0, as: UTF8.self) })
    }
    
    /// Creates a new string from a single UTF-16 code unit.
    public init(utf16CodeUnit: UTF16.CodeUnit) {
        self.init(utf16CodeUnits: [utf16CodeUnit], count: 1)
    }

    public subscript(
        _utf16Range range: Range<Int>
    ) -> Substring {
        let nsRange = NSRange(location: range.lowerBound, length: range.upperBound - range.lowerBound)
        
        return self[Range(nsRange, in: self)!]
    }
    
    public var _utf16Bounds: Range<Int> {
        _toUTF16Range(bounds)
    }
    
    public func _toUTF16Range(
        _ range: Range<String.Index>
    ) -> Range<Int> {
        let range = NSRange(range, in: self)
        
        return range.location..<(range.location + range.length)
    }
    
    public func _toUTF16Range(
        _ range: PartialRangeFrom<String.Index>
    ) -> Range<Int> {
        let range = NSRange(range, in: self)
        
        return range.location..<(range.location + range.length)
    }
}

extension String {
    public func delimited(by character: Character) -> String {
        "\(character)\(self)\(character)"
    }
}

extension String {
    public static func concatenate(
        separator: String,
        @_SpecializedArrayBuilder<String> _ strings: () throws -> [String]
    ) rethrows -> Self {
        try strings().joined(separator: separator)
    }
}

extension String {
    public func numberOfOccurences(of character: Character) -> Int {
        lazy.filter({ $0 == character }).count
    }
}

extension String {
    public func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + String(dropFirst())
    }
    
    public mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

extension String {
    public mutating func replaceSubstring(
        _ substring: Substring,
        with replacement: String
    ) {
        replaceSubrange(substring.bounds, with: replacement)
    }
    
    public mutating func replace(
        substrings: [Substring],
        with string: String
    ) {
        replaceSubranges(
            substrings.lazy.map({ $0.bounds }),
            with: substrings.lazy.map({ _ in string })
        )
    }
    
    public mutating func replace<String: StringProtocol>(
        occurencesOf target: String,
        with string: String
    ) {
        self = replacingOccurrences(of: target, with: string, options: .literal, range: nil)
    }
    
    public mutating func replace<String: StringProtocol>(
        firstOccurenceOf target: String,
        with string: String
    ) {
        TODO.whole(.remove, note: "replace with RangeReplaceableCollection function")
        
        guard let range = range(of: target, options: .literal) else {
            return
        }
        
        replaceSubrange(range, with: string)
    }
    
    public mutating func remove(substrings: [Substring]) {
        replace(substrings: substrings, with: "")
    }
}

extension String {
    public func removingCharacters(
        in characterSet: CharacterSet
    ) -> String {
        String(String.UnicodeScalarView(unicodeScalars.lazy.filter {
            !characterSet.contains($0)
        }))
    }

    public func removingCharacters(in string: String) -> String {
        removingCharacters(in: CharacterSet(charactersIn: string))
    }
    
    public func removingLeadingCharacters(
        in characterSet: CharacterSet
    ) -> String {
        guard let index = firstIndex(where: { !CharacterSet(charactersIn: String($0)).isSubset(of: characterSet) }) else {
            return self
        }
        
        return String(self[index...])
    }
    
    public func removingTrailingCharacters(
        in characterSet: CharacterSet
    ) -> String {
        guard let range = self.rangeOfCharacter(from: characterSet.inverted, options: .backwards) else {
            return ""
        }
        
        return String(self[..<range.upperBound])
    }

    @_disfavoredOverload
    public func trim(prefix: String, suffix: String) -> Substring {
        if hasPrefix(prefix) && hasSuffix(suffix) {
            return dropFirst(prefix.count).dropLast(suffix.count)
        } else {
            return self[bounds]
        }
    }
    
    public func trim(prefix: String, suffix: String) -> String {
        String(trim(prefix: prefix, suffix: suffix) as Substring)
    }
}

extension String {
    public func tabIndent(_ count: Int) -> String {
        return String(repeatElement("\t", count: count)) + self
    }
    
    public mutating func appendLine(_ string: String) {
        self += (string + "\n")
    }
    
    public mutating func appendTabIndentedLine( _ count: Int, _ string: String) {
        appendLine(String(repeatElement("\t", count: count)) + string)
    }
}

extension String {
    public func trimmingWhitespace() -> String {
        trimmingCharacters(in: .whitespaces)
    }
}

extension String {
    public func _componentsWithRanges(
        separatedBy separator: String
    ) -> [(String, Range<String.Index>)] {
        var ranges: [(String, Range<String.Index>)] = []
        var currentRangeStart = self.startIndex
        
        while let separatorRange = self.range(of: separator, options: [], range: currentRangeStart..<self.endIndex) {
            let componentRange = currentRangeStart..<separatorRange.lowerBound
            ranges.append((
                String(self[componentRange]),
                componentRange
            ))
            currentRangeStart = separatorRange.upperBound
        }
        ranges.append((
            String(self[currentRangeStart..<self.endIndex]),
            currentRangeStart..<self.endIndex
        ))
        
        return ranges
    }

    public func splitInHalf(separator: String) -> (String, String) {
        let range = range(of: separator, range: nil, locale: nil)
        
        if let range = range {
            let lhs = String(self[..<range.lowerBound])
            let rhs = String(self[range.upperBound...])
            return (lhs, rhs)
        }
        
        return (self, "")
    }
}
