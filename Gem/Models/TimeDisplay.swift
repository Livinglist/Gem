enum TimeDisplay {
    case timeAgo
    case dateTime
    
    mutating func toggle() {
        if self == .timeAgo {
            self = .dateTime
        } else {
            self = .timeAgo
        }
    }
}
