import SwiftData
import HackerNewsKit

@Model
class UserModel {
    var user: User?
    
    init(user: User? = nil) {
        self.user = user
    }
}
