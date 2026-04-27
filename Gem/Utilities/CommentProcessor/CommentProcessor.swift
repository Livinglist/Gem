import HackerNewsKit

protocol CommentProcessor {
    func process(_ comments: AsyncStream<(Int, Comment)>) -> AsyncStream<(Int, Comment)>
}
