import HackerNewsKit
import Translation

extension CommentTranslator {
    static let cache = NSCache<NSNumber, NSString>()
}

fileprivate protocol CommentTranslatable {
    func translate(_ comment: Comment) async -> Comment
}

#if targetEnvironment(simulator)
class CommentTranslator: CommentProcessor, CommentTranslatable {
    let targetLanguage: Locale.Language
    let session: TranslationSession
    
    struct LibreTranslateResponse: Decodable {
        let translatedText: String
    }
    
    init?(targetLanguage: Locale.Language) {
        self.targetLanguage = targetLanguage
        let config = TranslationSession.Configuration(source: .englishUS, target: targetLanguage)
        if let source = config.source, let target = config.target {
            self.session = TranslationSession(installedSource: source, target: target)
        } else {
            return nil
        }
    }
    
    func process(_ comments: AsyncStream<(Int, Comment)>) -> AsyncStream<(Int, Comment)> {
        AsyncStream { continuation in
            let task = Task.detached(priority: .userInitiated) { [self] in
                for await entry in comments {
                    let index = entry.0
                    let comment = entry.1
                    let translated = await translate(comment)
                    continuation.yield((index, translated))
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    fileprivate func translate(_ comment: Comment) async -> Comment {
        let cacheKey = NSNumber(integerLiteral: comment.id)
        if let cachedText = Self.cache.object(forKey: cacheKey) {
            return comment.copyWith(text: String(cachedText))
        }
        let url = URL(string: "http://localhost:5001/translate")!
        guard let body = try? JSONSerialization.data(withJSONObject: [
            "q": comment.text.orEmpty,
            "source": session.sourceLanguage?.languageCode?.identifier,
            "target": session.targetLanguage?.languageCode?.identifier,
            "format": "text"
        ]) else { return comment }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let translatedText = try? JSONDecoder().decode(LibreTranslateResponse.self, from: data).translatedText
        else { return comment }
        Self.cache.setObject(NSString(string: translatedText), forKey: cacheKey)
        return comment.copyWith(text: translatedText)
    }
}
#else
class CommentTranslator: CommentProcessor, CommentTranslatable {
    let targetLanguage: Locale.Language
    let session: TranslationSession
    
    init?(targetLanguage: Locale.Language) {
        self.targetLanguage = targetLanguage
        let config = TranslationSession.Configuration(source: .englishUS, target: targetLanguage)
        //        if #available(iOS 26.4, *) {
        //            config.preferredStrategy = .lowLatency
        //        }
        if let source = config.source, let target = config.target {
            self.session = TranslationSession(installedSource: source, target: target)
        } else {
            return nil
        }
    }
    
    func process(_ comments: AsyncStream<(Int, Comment)>) -> AsyncStream<(Int, Comment)> {
        AsyncStream { continuation in
            Task.detached(priority: .userInitiated) { [self] in
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
    
    fileprivate func translate(_ comment: Comment) async -> Comment {
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
#endif
