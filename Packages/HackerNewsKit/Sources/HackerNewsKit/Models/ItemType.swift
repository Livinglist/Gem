nonisolated
public enum ItemType: Codable, CaseIterable {
    case story, comment
}

public extension ItemType {
    var label: String {
        switch self {
        case .story: return "Story"
        case .comment: return "Comment"
        }
    }
}
