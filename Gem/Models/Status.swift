public enum Status {
    case idle
    /// Loading with visible loading indicator.
    case inProgress
    /// Loading with no loading indicator.
    case backgroundLoading
    case refreshing
    case completed
    case error
    
    var isLoading: Bool {
        switch self {
        case .inProgress, .backgroundLoading: return true
        default: return false
        }
    }
    
    var isCompleted: Bool {
        self == .completed
    }
}
