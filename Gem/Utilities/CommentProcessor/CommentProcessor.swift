import HackerNewsKit

protocol CommentProcessor {
    func process(_ comments: AsyncStream<Comment>) -> AsyncStream<Comment>
}
