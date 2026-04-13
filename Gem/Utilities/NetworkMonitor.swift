import Network
import Combine

final class NetworkMonitor: ObservableObject {
    let networkStatus = CurrentValueSubject<Bool?, Never>(nil)
    @Published var isOnWifi = true
    @Published var isOnCellular = true

    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    static let shared = NetworkMonitor()
    
    init() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            
            networkStatus.send(path.status == .satisfied)
            isOnWifi = path.usesInterfaceType(.wifi)
            isOnCellular = path.usesInterfaceType(.cellular)
        }
        
        pathMonitor.start(queue: monitorQueue)
    }
}
