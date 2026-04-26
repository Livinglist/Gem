import HackerNewsKit

class CommentFactory {
    public var processors: [CommentProcessor] = []
    
    init(processors: [CommentProcessor]) {
        self.processors = processors
    }
    
    func append(_ processor: CommentProcessor) {
        processors.append(processor)
    }
    
    func process(_ comments: [Comment]) -> AsyncStream<Comment> {
        // Wrap the initial array as a stream
        var stream = AsyncStream<Comment> { continuation in
            comments.forEach { continuation.yield($0) }
            continuation.finish()
        }
        
        for processor in processors {
            stream = processor.process(stream)
        }
        
        return stream
    }
}
