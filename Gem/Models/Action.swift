/// Used for deciding which image or text to be shown in Toast alert.

import UIKit
enum Action: Equatable {
    case flag
    case upvote
    case downvote
    case favorite
    case unfavorite
    case pin
    case unpin
    case block
    case unblock
    case login
    case reply
    case copy
    case lazyFetching
    case eagerFetching
    case failure
    case none

    var feedback: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .flag, 
             .upvote,
             .downvote,
             .unfavorite,
             .pin, 
             .unpin,
             .block,
             .unblock,
             .login,
             .reply,
             .copy,
             .lazyFetching,
             .eagerFetching:
            return .success
        case .failure:
            return .error
        default:
            return .success
        }
    }

    var label: String {
        switch self {
        case .flag:
            return "Flag"
        case .upvote:
            return "Upvote"
        case .downvote:
            return "Downvote"
        case .favorite:
            return "Favorite"
        case .unfavorite:
            return "Unfavorite"
        case .pin:
            return "Pin"
        case .unpin:
            return "Unpin"
        case .block:
            return "Block"
        case .unblock:
            return "Unblock"
        case .login:
            return "Log in"
        case .reply:
            return "Reply"
        case .copy:
            return "Copy"
        case .failure:
            return .init()
        case .lazyFetching:
            fallthrough
        case .eagerFetching:
            fallthrough
        case .none:
            return .init()
        }
    }

    var icon: String {
        switch self {
        case .flag:
            return "flag"
        case .upvote:
            return "hand.thumbsup"
        case .downvote:
            return "hand.thumbsdown"
        case .favorite:
            return "heart"
        case .unfavorite:
            return "heart.slash"
        case .pin:
            return "pin"
        case .unpin:
            return "pin.slash"
        case .block:
            return "eye.slash"
        case .unblock:
            return "eye"
        case .login:
            return "person"
        case .reply:
            return "plus.message"
        case .copy:
            return "doc.on.doc"
        case .failure:
            return .init()
        case .lazyFetching:
            return "line.3.horizontal.circle"
        case .eagerFetching:
            return "line.3.horizontal.decrease.circle"
        case .none:
            return .init()
        }
    }

    /// The icon to be displayed in the `Toast`.
    /// Should always be a system image.
    var completionIcon: String {
        switch self {
        case .flag:
            return "flag.fill"
        case .upvote:
            return "hand.thumbsup.fill"
        case .downvote:
            return "hand.thumbsdown.fill"
        case .favorite:
            return "heart.fill"
        case .unfavorite:
            return "heart.slash"
        case .pin:
            return "pin.fill"
        case .unpin:
            return "pin.slash"
        case .block:
            return "eye.slash"
        case .unblock:
            return "eye"
        case .login:
            return "person.badge.shield.checkmark.fill"
        case .reply:
            return "arrowshape.turn.up.left.circle.fill"
        case .copy:
            return "doc.on.doc.fill"
        case .failure:
            return "wrongwaysign"
        case .lazyFetching:
            return "line.3.horizontal.circle.fill"
        case .eagerFetching:
            return "line.3.horizontal.decrease.circle.fill"
        case .none:
            return .init()
        }
    }

    /// The label to be displayed in the `Toast`.
    var completionLabel: String {
        switch self {
        case .flag:
            return "Flagged"
        case .upvote:
            return "Upvoted"
        case .downvote:
            return "Downvoted"
        case .favorite:
            return "Added"
        case .unfavorite:
            return "Removed"
        case .pin:
            return "Pinned"
        case .unpin:
            return "Unpinned"
        case .block:
            return "Blocked"
        case .unblock:
            return "Unblocked"
        case .login:
            return "Welcome"
        case .reply:
            return "Replied"
        case .copy:
            return "Copied"
        case .failure:
            return "Error"
        case .lazyFetching:
            return "Lazy Fetching"
        case .eagerFetching:
            return "Eager Fetching"
        case .none:
            return .init()
        }
    }
}
