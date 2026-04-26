import HackerNewsKit
import Translation

extension CommentTranslator {
    static let cache = NSCache<NSNumber, NSString>()
}

class CommentTranslator: CommentProcessor {
    let targetLanguage: Locale.Language
    let session: TranslationSession
    
    init?(targetLanguage: Locale.Language) {
        self.targetLanguage = targetLanguage
        let config = TranslationSession.Configuration(source: .englishUS, target: targetLanguage)
        if let source = config.source, let target = config.target {
            self.session = TranslationSession(installedSource: source, target: target)
        } else {
            return nil
        }
    }
    
    func process(_ comments: AsyncStream<Comment>) -> AsyncStream<Comment> {
        AsyncStream { continuation in
            Task {
                for await comment in comments {
                    let translated = await translate(comment)
                    continuation.yield(translated)
                }
                continuation.finish()
            }
        }
    }
    
    private func translate(_ comment: Comment) async -> Comment {
        try? await session.prepareTranslation()
        let cacheKey = NSNumber(integerLiteral: comment.id)
        if let cachedText = Self.cache.object(forKey: cacheKey) {
            return comment.copyWith(text: String(cachedText))
        }
        guard let response = try? await session.translate(comment.text.orEmpty) else { return comment }
        let translatedText = response.targetText
        Self.cache.setObject(NSString(string: translatedText), forKey: cacheKey)
        return comment.copyWith(text: response.targetText)
    }
}
