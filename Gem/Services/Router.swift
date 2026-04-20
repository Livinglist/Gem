import Combine
import SwiftUI
import HackerNewsKit

@Observable class Router {
    var path: NavigationPath = .init()
    var sheetPath: NavigationPath = .init()
    var isProfileSheetPresented: Bool = false
    
    static let shared: Router = .init()
    
    private init() {}
    
    func to(_ destination: Destination) {
        if isProfileSheetPresented {
            sheetPath.append(destination)
        } else {
            path.append(destination)
        }
    }
    
    func to(_ item: any Item) {
        if isProfileSheetPresented {
            sheetPath.append(item)
        } else {
            path.append(item)
        }
    }
}
