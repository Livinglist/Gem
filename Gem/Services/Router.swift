import SwiftUI
import HackerNewsKit

class Router: ObservableObject {
    @Published var path: NavigationPath = .init()
    
    static let shared: Router = .init()
    
    private init() {}
    
    func to(_ destination: Destination) {
        path.append(destination)
    }
    
    func to(_ item: any Item) {
        path.append(item)
    }
}
