import Foundation
import HackerNewsKit

extension String {
    nonisolated var isNotEmpty: Bool {
        !isEmpty
    }
    
    var markdowned: AttributedString {
        var str = self
        str = str.replacingOccurrences(of: "\n**", with: "**")
        if let attributedString = try? AttributedString(
            markdown: str, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributedString
        } else {
            return AttributedString(stringLiteral: self)
        }
    }
    
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
    
    var itemId: Int? {
        let itemId = /item\?id=[0-9]+/
        let digits = /[0-9]+/
        
        if let id = Int(self) {
            return id
        }
        
        if let match = self.firstMatch(of: itemId),
           let idMatch = String(match.0).firstMatch(of: digits),
           let id = Int(String(idMatch.0)) {
            return id
        }
        
        return nil
    }
}

extension Optional where Wrapped == String {
    nonisolated var orEmpty: String {
        guard let unwrapped = self else {
            return ""
        }
        return unwrapped
    }
    
    var htmlStripped: String{
        guard let unwrapped = self else {
            return ""
        }
        
        return unwrapped.htmlStripped
    }
    
    var isNotNullOrEmpty: Bool {
        guard let unwrapped = self else {
            return false
        }
        
        return unwrapped.isNotEmpty
    }
    
    func ifNullOrEmpty(then str: String) -> String {
        guard let unwrapped = self else {
            return str
        }
        
        return unwrapped.isEmpty ? str : unwrapped
    }
}
