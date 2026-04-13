import SwiftUI
import HackerNewsKit

enum Destination: Hashable {
    case pin
    case fav
    case search
    case submission([Int])
    case profile(String)
    case url(URL)
    case replyComment(Comment)
    case replyStory(Story)
    case settings

    @ViewBuilder
    func toView() -> some View {
        switch self {
        case .pin:
            Pins()
        case .fav:
            Favorites()
        case .search:
            Search()
        case let .submission(ids):
            Submissions(ids: ids)
        case let .profile(username):
            Profile(id: username)
        case let .url(url):
            WebView(url: url)
        case let .replyComment(cmt):
            ReplyView(replyingTo: cmt)
        case let .replyStory(story):
            ReplyView(replyingTo: story)
        case .settings:
            Settings()
        }
    }
}
