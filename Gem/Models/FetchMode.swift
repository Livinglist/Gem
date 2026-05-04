enum FetchMode: Int, Equatable, CaseIterable {
    case eager = 0
    case lazy = 1
    
    var label: String {
        switch self {
        case .eager: return "Eager"
        case .lazy: return "Lazy"
        }
    }
    
    var systemImage: String {
        switch self {
        case .eager: return "square.stack"
        case .lazy: return "square.stack.3d.up"
        }
    }
}
