import Foundation

class MarkdownParser {
    private let cache = NSCache<NSNumber, NSAttributedString>()
    
    static let shared = MarkdownParser()
    
    func markdown(id: Int, text: String) -> AttributedString {
        let cacheKey = NSNumber(integerLiteral: id)
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
}
