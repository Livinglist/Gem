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
        var config = TranslationSession.Configuration(source: .englishUS, target: targetLanguage)
        if #available(iOS 26.4, *) {
            config.preferredStrategy = .lowLatency
        }
        if let source = config.source, let target = config.target {
            self.session = TranslationSession(installedSource: source, target: target)
        } else {
            return nil
        }
    }
    
    func process(_ comments: AsyncStream<(Int, Comment)>) -> AsyncStream<(Int, Comment)> {
        AsyncStream { continuation in
            Task {
                for await entry in comments {
                    let index = entry.0
                    let comment = entry.1
                    let translated = await translate(comment)
                    continuation.yield((index, translated))
                }
                continuation.finish()
            }
        }
    }
    
    private func translate(_ comment: Comment) async -> Comment {
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
