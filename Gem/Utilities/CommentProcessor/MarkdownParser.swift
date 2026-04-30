import HackerNewsKit
import Foundation
import Logging

private var caches: [String: NSCache<NSString, NSAttributedString>] = [:]

extension MarkdownParser {
    static let shared = MarkdownParser(language: .englishUS)
}

class MarkdownParser: CommentProcessor {
    let language: Locale.Language
    
    init(language: Locale.Language) {
        self.language = language
    }
    
    func markdown(id: Int, text: String) -> AttributedString {
        let cacheKey = NSString(string: "\(id)")
        guard let languageIdentifier = language.languageCode?.identifier else {
            return AttributedString(stringLiteral: text)
        }
        var cache = caches[languageIdentifier]
        
        if cache == nil {
            cache = NSCache<NSString, NSAttributedString>()
            caches[languageIdentifier] = cache
        }
        
        guard let cache else { return AttributedString(stringLiteral: text) }
        
        if let cachedStr = cache.object(forKey: cacheKey) {
            return AttributedString(cachedStr)
        }
        var str = text
        str = str.replacingOccurrences(of: "\n**", with: "**")
        var result: AttributedString = .init()
        if let attributedString = try? AttributedString(
            markdown: str, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            result = attributedString
        } else {
            result = AttributedString(stringLiteral: str)
        }
        
        cache.setObject(NSAttributedString(result), forKey: cacheKey)
        return result
    }
    
    func process(_ comments: AsyncStream<(Int, Comment)>) -> AsyncStream<(Int, Comment)> {
        return AsyncStream { continuation in
            Task.detached(priority: .userInitiated) { [self] in
                for await entry in comments {
                    let comment = entry.1
                    _ = await markdown(id: comment.id, text: comment.text.orEmpty)
                    continuation.yield(entry)
                }
                continuation.finish()
            }
        }
    }
    
    static func getCachedAttributedString(id: Int, language: Locale.Language) -> AttributedString? {
        let cacheKey = NSString(string: "\(id)")
        guard let languageIdentifier = language.languageCode?.identifier else { return nil }
        var cache = caches[languageIdentifier]
        
        if cache == nil {
            cache = NSCache<NSString, NSAttributedString>()
            caches[languageIdentifier] = cache
        }
        
        if let cachedNSAttributedString = cache?.object(forKey: cacheKey) {
            return AttributedString(cachedNSAttributedString)
        }
        
        return nil
    }
}
