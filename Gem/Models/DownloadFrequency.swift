import Foundation

enum DownloadFrequency: TimeInterval, Equatable, CaseIterable {
    case oneWeek = 604800
    case oneDay = 86400
    case halfDay = 43200
    case fourHours = 14400
    case oneHour = 3600
    
    var label: String {
        switch self {
        case .oneWeek: return "Every Week"
        case .oneDay: return "Every Day"
        case .halfDay: return "Every 12 Hours"
        case .fourHours: return "Every 4 Hours"
        case .oneHour: return "Every One Hour"
        }
    }
}
