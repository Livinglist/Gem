import Foundation

struct IdentifiableURL: Identifiable {
    var id: String { self.url.absoluteString }
    let url: URL
}
