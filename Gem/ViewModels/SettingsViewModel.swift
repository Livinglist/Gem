import Foundation
import InMemoryLogging
import Logging
import Translation
import HackerNewsKit
import Combine

extension SettingsViewModel {
    var isTranslationAvailable: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return isTranslationEnabled
#endif
    }
}

extension SettingsViewModel {
    private func setUpLogger() {
        if isDevModeEnabled {
            Logger.enableInMemoryLogHandler()
        } else {
            Logger.disableInMemoryLogHandler()
        }
    }
}

fileprivate extension String {
    static let blockListKey = "blockListKey"
    static let isAutomaticDownloadEnabledKey = "isAutomaticDownloadEnabled"
    static let useCellularDataKey = "useCellularData"
    static let downloadFrequencyKey = "downloadFrequency"
    static let defaultStoryTypeKey = "defaultStoryType"
    static let defaultFetchModeKey = "defaultFetchMode"
    static let appOpenCounterKey = "appOpenCounter"
    static let isAutoScrollEnabledKey = "isAutoScrollEnabled"
    static let isTranslationEnabledKey = "isTranslationEnabled"
    static let translationTargetKey = "translationTarget"
    static let isDevModeEnabledKey = "isDevModeEnabled"
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
    var isAutoScrollEnabled: Bool = .init() {
        didSet {
            UserDefaults.standard.set(isAutoScrollEnabled, forKey: .isAutoScrollEnabledKey)
        }
    }
    var appOpenCounter: Int = 0 {
        didSet {
            UserDefaults.standard.setValue(appOpenCounter, forKey: .appOpenCounterKey)
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
    var isDevModeEnabled: Bool = .init() {
        didSet {
            UserDefaults.standard.set(isDevModeEnabled, forKey: .isDevModeEnabledKey)
            setUpLogger()
        }
    }
    
    // MARK: - Translation
    var isTranslationEnabled: Bool = .init() {
        didSet {
            UserDefaults.standard.set(isTranslationEnabled, forKey: .isTranslationEnabledKey)
            let config = TranslationSession.Configuration(source: .englishUS, target: translationTarget)
            translationConfig = config
        }
    }
    var translationTarget: Locale.Language = .init(languageCode: .spanish) {
        didSet {
            UserDefaults.standard.setValue(translationTarget.languageCode?.identifier, forKey: .translationTargetKey)
            CommentTranslator.cache.removeAllObjects()
            let config = TranslationSession.Configuration(source: .englishUS, target: translationTarget)
            translationConfig = config
        }
    }
    var translationConfig: TranslationSession.Configuration?
    
    let supportedLanguages: [Locale.Language] = [
        .init(languageCode: .spanish),
        .init(languageCode: .french),
        .init(languageCode: .german),
        .init(languageCode: .japanese),
        .init(languageCode: .korean),
        .init(languageCode: .chinese),
        .init(languageCode: .arabic),
        .init(languageCode: .portuguese),
        .init(languageCode: .italian),
    ]
    
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
        isAutoScrollEnabled = (UserDefaults.standard.object(forKey: .isAutoScrollEnabledKey) as? Bool) ?? true
        isDevModeEnabled = (UserDefaults.standard.object(forKey: .isDevModeEnabledKey) as? Bool) ?? false
        isTranslationEnabled = (UserDefaults.standard.object(forKey: .isTranslationEnabledKey) as? Bool) ?? false
        let targetLanguageIdentifier = UserDefaults.standard.object(forKey: .translationTargetKey) as? String
        
#if targetEnvironment(simulator)
        translationTarget = .init(languageCode: .chinese)
#else
        translationTarget = targetLanguageIdentifier == nil ? .init(languageCode: .spanish) : .init(identifier: targetLanguageIdentifier!)
#endif

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
