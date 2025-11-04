import Foundation
import Network

/// Network monitor for checking connectivity
actor NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private var isConnected: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.updateConnected(path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnected(_ connected: Bool) {
        isConnected = connected
    }
    
    /// Checks if device is connected to network
    func checkConnectivity() async -> Bool {
        return isConnected
    }
}

