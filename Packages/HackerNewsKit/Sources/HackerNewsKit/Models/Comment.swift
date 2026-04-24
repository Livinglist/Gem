public struct Comment: Item, Equatable {
    public let id: Int
    public let parent: Int?
    public let text: String?
    public let type: String?
    public let by: String?
    public let time: Int
    public let kids: [Int]?
    public let level: Int?
    public let isCollapsed: Bool?
    public let isHidden: Bool?
    public let isReply: Bool?
    
    /// Values below will always be nil for `Comment`.
    public let title: String?
    public let url: String?
    public let descendants: Int?
    public let score: Int?
    
    public var metadata: String {
        if let count = kids?.count, count != 0 {
            return "\(count) cmt\(count > 1 ? "s":"") | \(timeAgo) by \(by.orEmpty)"
        } else {
            return "\(timeAgo) by \(by.orEmpty)"
        }
    }
    
    public init(id: Int, parent: Int?, text: String?, by: String?, time: Int, kids: [Int]? = [Int](), level: Int? = 0, isCollapsed: Bool = false, isHidden: Bool = false, isReply: Bool = false) {
        self.id = id
        self.parent = parent
        self.text = text
        self.by = by
        self.time = time
        self.kids = kids
        self.level = level
        self.type = "comment"
        self.title = nil
        self.url = nil
        self.descendants = nil
        self.score = nil
        self.isCollapsed = isCollapsed
        self.isHidden = isHidden
        self.isReply = isReply
    }
    
    // Empty initializer
    init() {
        self.init(id: 0, parent: 0, text: "", by: "", time: 0)
    }
    
    public func copyWith(text: String? = nil, level: Int? = nil, isCollapsed: Bool? = nil, isHidden: Bool? = nil, isReply: Bool? = nil) -> Comment {
        Comment(id: id,
                parent: parent,
                text: text ?? self.text,
                by: by,
                time: time,
                kids: kids ?? [Int](),
                level: level ?? self.level,
                isCollapsed: isCollapsed ?? self.isCollapsed ?? false,
                isHidden: isHidden ?? self.isHidden ?? false,
                isReply: isReply ?? self.isReply ?? false)
    }
    
    public static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id && lhs.isCollapsed == rhs.isCollapsed && lhs.isHidden == rhs.isHidden
    }
}
