import Foundation
import HackerNewsKit
import Combine

fileprivate extension String {
    static let blockListKey = "blockListKey"
    static let isAutomaticDownloadEnabledKey = "isAutomaticDownloadEnabled"
    static let useCellularDataKey = "useCellularData"
    static let downloadFrequencyKey = "downloadFrequency"
    static let defaultStoryTypeKey = "defaultStoryType"
    static let defaultFetchModeKey = "defaultFetchMode"
    static let appOpenCounterKey = "appOpenCounter"
}

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

@Observable class SettingsViewModel {
    var blocklist: Set<String> = .init()
    var isAutomaticDownloadEnabled: Bool = .init() {
        didSet {
            UserDefaults.standard.set(isAutomaticDownloadEnabled, forKey: .isAutomaticDownloadEnabledKey)
        }
    }
    var useCellularData: Bool = .init() {
        didSet {
            UserDefaults.standard.set(useCellularData, forKey: .useCellularDataKey)
        }
    }
    var appOpenCounter: Int = 0 {
        didSet {
            if appOpenCounter <= 10 {
                UserDefaults.standard.setValue(appOpenCounter, forKey: .appOpenCounterKey)
            }
        }
    }
    var downloadFrequency: DownloadFrequency = .oneDay {
        didSet {
            UserDefaults.standard.setValue(downloadFrequency.rawValue, forKey: .downloadFrequencyKey)
        }
    }
    var defaultStoryType: StoryType = .top {
        didSet {
            UserDefaults.standard.setValue(defaultStoryType.rawValue, forKey: .defaultStoryTypeKey)
        }
    }
    var defaultFetchMode: FetchMode = .eager {
        didSet {
            UserDefaults.standard.setValue(defaultFetchMode.rawValue, forKey: .defaultFetchModeKey)
        }
    }
    
    static let shared: SettingsViewModel = .init()
    
    private init() {
        if let blocklist = UserDefaults.standard.array(forKey: .blockListKey) as? [String] {
            self.blocklist = Set(blocklist)
        } else {
            UserDefaults.standard.set([String](), forKey: .blockListKey)
        }
        
        appOpenCounter = UserDefaults.standard.integer(forKey: .appOpenCounterKey)
        isAutomaticDownloadEnabled = UserDefaults.standard.bool(forKey: .isAutomaticDownloadEnabledKey)
        useCellularData = UserDefaults.standard.bool(forKey: .useCellularDataKey)
        
        let downloadFrequencyRawValue = UserDefaults.standard.double(forKey: .downloadFrequencyKey)
        if let downloadFrequency = DownloadFrequency(rawValue: downloadFrequencyRawValue) {
            self.downloadFrequency = downloadFrequency
        }
        
        if let defaultStoryTypeRawValue = UserDefaults.standard.string(forKey: .defaultStoryTypeKey),
           let defaultStoryType = StoryType(rawValue: defaultStoryTypeRawValue) {
            self.defaultStoryType = defaultStoryType
        }
        
        let defaultFetchModeRawValue = UserDefaults.standard.integer(forKey: .defaultFetchModeKey)
        if let defaultFetchMode = FetchMode(rawValue: defaultFetchModeRawValue) {
            self.defaultFetchMode = defaultFetchMode
        }
    }
    
    func block(_ id: String) -> Void {
        blocklist.insert(id)
        UserDefaults.standard.set(Array(blocklist), forKey: .blockListKey)
    }
    
    func unblock(_ id: String) -> Void {
        blocklist.remove(id)
        UserDefaults.standard.set(Array(blocklist), forKey: .blockListKey)
    }
}
