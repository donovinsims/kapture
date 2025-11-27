#if canImport(SwiftUI)
import SwiftUI

@main
struct KaptureApp: App {
    @StateObject private var appState = AppState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Pre-load critical resources for fast launch
        preloadCriticalResources()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    // Handle OAuth callback URL
                    Task {
                        do {
                            try await AuthService.shared.handleOAuthCallback(url)
                        } catch {
                            // Log error but don't show UI here - AuthService handles it
                            print("OAuth callback error: \(error.localizedDescription)")
                        }
                    }
                }
                .onAppear {
                    // Lazy load non-critical components
                    loadNonCriticalComponents()
                }
        }
    }
    
    private func preloadCriticalResources() {
        // Load token from Keychain (fast operation)
        // Initialize minimal UI state
        // Skip heavy network calls
        
        // Initialize StorageService
        Task {
            try? await StorageService.shared.configure()
        }
    }
    
    private func loadNonCriticalComponents() {
        // Background initialization of non-critical services
    }
}

/// App delegate for handling lifecycle events
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Schedule background sync if needed
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle OAuth callback
        Task {
            do {
                try await AuthService.shared.handleOAuthCallback(url)
            } catch {
                // Log error - AuthService will update authenticationError state
                print("OAuth callback error: \(error.localizedDescription)")
            }
        }
        return true
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var authService = AuthService.shared
    
    // Development flag: set to true to bypass authentication
    private let bypassAuth = true
    
    var body: some View {
        Group {
            if bypassAuth || authService.isAuthenticated {
                CaptureView()
            } else {
                WelcomeView()
            }
        }
        .task {
            if !bypassAuth {
                await authService.checkAuthenticationStatus()
            }
        }
    }
}

// App state management
class AppState: ObservableObject {
    @Published var isConnected: Bool = true
    @Published var syncStatus: SyncStatus = .pending
    
    init() {
        // Initialize app state
    }
}

#endif

