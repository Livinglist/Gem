import Foundation

struct Constants {
    static let githubUrl = URL(string: "https://github.com/Livinglist/ZCombinator")!
    static let server = "news.ycombinator.com"
    static let happyFace = [
        "(๑•̀ㅂ•́)و✧",
        "( ͡• ͜ʖ ͡•)",
        "( ͡~ ͜ʖ ͡°)",
        "٩(˘◡˘)۶",
        "(─‿‿─)",
        "(¬‿¬)",
    ].randomElement().orEmpty
    
    struct AppNotification {
        static let lastItemPushedKey = "lastItemPushed"
        static let lastFetchedAtKey = "lastFetchedAt"
        static let backgroundTaskId = "fetchReplies"
    }
    
    struct Download {
        static let backgroundTaskId = "download"
    }
}
