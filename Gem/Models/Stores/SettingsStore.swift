import Foundation
import HackerNewsKit

fileprivate extension String {
    static let favListKey = "favList"
    static let pinListKey = "pinList"
    static let blockListKey = "blockListKey"
    static let isAutomaticDownloadEnabledKey = "isAutomaticDownloadEnabled"
    static let useCellularDataKey = "useCellularData"
    static let downloadFrequencyKey = "downloadFrequency"
    static let defaultStoryTypeKey = "defaultStoryType"
    static let defaultFetchModeKey = "defaultFetchMode"
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
}

class SettingsStore: ObservableObject {
    @Published var favList: [Int] = .init()
    @Published var pinList: [Int] = .init()
    @Published var blocklist: Set<String> = .init()
    @Published var isAutomaticDownloadEnabled: Bool = .init() {
        didSet {
            UserDefaults.standard.set(isAutomaticDownloadEnabled, forKey: .isAutomaticDownloadEnabledKey)
        }
    }
    @Published var useCellularData: Bool = .init() {
        didSet {
            UserDefaults.standard.set(useCellularData, forKey: .useCellularDataKey)
        }
    }
    @Published var downloadFrequency: DownloadFrequency = .oneDay {
        didSet {
            UserDefaults.standard.setValue(downloadFrequency.rawValue, forKey: .downloadFrequencyKey)
        }
    }
    @Published var defaultStoryType: StoryType = .top {
        didSet {
            UserDefaults.standard.setValue(defaultStoryType.rawValue, forKey: .defaultStoryTypeKey)
        }
    }
    @Published var defaultFetchMode: FetchMode = .eager {
        didSet {
            UserDefaults.standard.setValue(defaultFetchMode.rawValue, forKey: .defaultFetchModeKey)
        }
    }

    static let shared: SettingsStore = .init()

    private init() {
        if let favList = UserDefaults.standard.array(forKey: .favListKey) as? [Int] {
            self.favList = Array(favList)
        } else {
            UserDefaults.standard.set([Int](), forKey: .favListKey)
        }
        
        if let pinList = UserDefaults.standard.array(forKey: .pinListKey) as? [Int] {
            self.pinList = Array(pinList)
        } else {
            UserDefaults.standard.set([Int](), forKey: .pinListKey)
        }

        if let blocklist = UserDefaults.standard.array(forKey: .blockListKey) as? [String] {
            self.blocklist = Set(blocklist)
        } else {
            UserDefaults.standard.set([String](), forKey: .blockListKey)
        }

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
    
    func onFavToggle(_ id: Int) -> Void {
        if favList.contains(id) {
            favList.removeAll { $0 == id }
        } else {
            favList.append(id)
        }
        UserDefaults.standard.set(Array(favList), forKey: .favListKey)
    }
    
    func onPinToggle(_ id: Int) -> Void {
        if pinList.contains(id) {
            pinList.removeAll { $0 == id }
        } else {
            pinList.append(id)
        }
        UserDefaults.standard.set(Array(pinList), forKey: .pinListKey)
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
