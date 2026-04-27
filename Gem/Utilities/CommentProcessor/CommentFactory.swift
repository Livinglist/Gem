import HackerNewsKit

class CommentFactory {
    public var processors: [CommentProcessor] = []
    
    init(processors: [CommentProcessor]) {
        self.processors = processors
    }
    
    func append(_ processor: CommentProcessor) {
        processors.append(processor)
    }
    
    func process(_ comments: [Comment]) -> AsyncStream<(Int, Comment)> {
        // Wrap the initial array as a stream
        var stream = AsyncStream<(Int, Comment)> { continuation in
            for (index, comment) in comments.enumerated() {
                continuation.yield((index, comment))
            }
            
            continuation.finish()
        }
        
        for processor in processors {
            stream = processor.process(stream)
        }
        
        return stream
    }
}
