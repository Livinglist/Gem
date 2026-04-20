import Foundation
import Alamofire

public class StoryRepository {
    public static let shared: StoryRepository = .init()
    
    private let baseUrl: String = "https://hacker-news.firebaseio.com/v0/"
    private let session: Session
    
    public init(session: Session = .default) {
        self.session = session
    }
    
    // MARK: - Story related.
    
    public func fetchAllStories(from storyType: StoryType) async -> [Story] {
        let storyIds = await fetchStoryIds(from: storyType)
        let stories: [Story] = await withTaskGroup(of: (Int, (Story)?).self) { group in
            for (index, id) in storyIds.enumerated() {
                group.addTask { [self] in
                    guard let story = await fetchStory(id) else { return (index, nil) }
                    return (index, story)
                }
            }
            
            var items: [(Int, Story?)] = []
            for await result in group {
                items.append(result)
            }
            return items
                .sorted { $0.0 < $1.0 }
                .compactMap { $0.1 }
        }
        return stories
    }
    
    public func fetchStoryIds(from storyType: StoryType) async -> [Int] {
        let response =  await session.request("\(self.baseUrl)\(storyType.rawValue)stories.json").serializingString().response
        guard response.data != nil else { return [Int]() }
        let storyIds = try? JSONDecoder().decode([Int].self, from: response.data!)
        return storyIds ?? [Int]()
    }
    
    public func fetchStoryIds(from storyType: String) async -> [Int] {
        let response =  await session.request("\(self.baseUrl)\(storyType)stories.json").serializingString().response
        guard response.data != nil else { return [Int]() }
        let storyIds = try? JSONDecoder().decode([Int].self, from: response.data!)
        return storyIds ?? [Int]()
    }
    
    public func fetchStories(ids: [Int], onStoryFetched: @escaping (Story) -> Void) async -> Void {
        for id in ids {
            let story = await fetchStory(id)
            if let story = story {
                onStoryFetched(story)
            }
        }
    }
    
    public func fetchStory(_ id: Int) async -> Story?{
        let response = await session.request("\(self.baseUrl)item/\(id).json").serializingString().response
        if let data = response.data,
           var story = try? JSONDecoder().decode(Story.self, from: data) {
            let formattedText = story.text.htmlStripped
            story = story.copyWith(text: formattedText)
            return story
        } else {
            return nil
        }
    }
    
    // MARK: - Comment related.
    
    public func fetchComments(ids: [Int]) async -> [Comment] {
        let comments = await withTaskGroup(of: (Int, Comment?).self) { group in
            for (index, id) in ids.enumerated() {
                group.addTask { [self] in
                    guard let comment = await fetchComment(id) else { return (index, nil) }
                    return (index, comment)
                }
            }
            
            var comments: [(Int, Comment?)] = []
            for await result in group {
                comments.append(result)
            }
            return comments
                .sorted { $0.0 < $1.0 }
                .compactMap { $0.1 }
        }
        return comments
    }
    
    public func fetchComment(_ id: Int) async -> Comment? {
        let response = await session.request("\(self.baseUrl)item/\(id).json").serializingString().response
        if let data = response.data,
           var comment = try? JSONDecoder().decode(Comment.self, from: data) {
            let formattedText = comment.text.htmlStripped
            comment = comment.copyWith(text: formattedText)
            return comment
        } else {
            return nil
        }
    }
    
    // MARK: - Item related.
    
    public func fetchItems(ids: [Int]) async -> [any Item] {
        let items: [any Item] = await withTaskGroup(of: (Int, (any Item)?).self) { group in
            for (index, id) in ids.enumerated() {
                group.addTask { [self] in
                    guard let comment = await fetchItem(id) else { return (index, nil) }
                    return (index, comment)
                }
            }
            
            var items: [(Int, (any Item)?)] = []
            for await result in group {
                items.append(result)
            }
            return items
                .sorted { $0.0 < $1.0 }
                .compactMap { $0.1 }
                .compactMap { item in
                    switch item {
                    case let item as Story: return item as Story
                    case let item as Comment: return item as Comment
                    default: return item
                    }
                }
        }
        return items
    }
    
    public func fetchItem(_ id: Int) async -> (any Item)? {
        let response = await session.request("\(self.baseUrl)item/\(id).json").serializingString().response
        if let data = response.data,
           let result = try? response.result.get(),
           let map = result.toJSON() as? [String: AnyObject],
           let type = map["type"] as? String {
            switch type {
            case "story":
                let story = try? JSONDecoder().decode(Story.self, from: data)
                let formattedText = story?.text.htmlStripped
                return story?.copyWith(text: formattedText)
            case "comment":
                let comment = try? JSONDecoder().decode(Comment.self, from: data)
                let formattedText = comment?.text.htmlStripped
                return comment?.copyWith(text: formattedText)
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    // MARK: - User related.
    
    public func fetchUser(_ id: String) async -> User? {
        let response = await session.request("\(self.baseUrl)/user/\(id).json").serializingString().response
        if let data = response.data,
           let user = try? JSONDecoder().decode(User.self, from: data) {
            let formattedText = user.about.orEmpty.htmlStripped
            return user.copyWith(about: formattedText)
        } else {
            return nil
        }
    }
}
