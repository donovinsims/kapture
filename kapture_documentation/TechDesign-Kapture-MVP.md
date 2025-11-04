# Technical Design Document: Kapture MVP

## Executive Summary

**System:** Kapture  
**Version:** MVP 1.0  
**Architecture Pattern:** MVVM with Combine  
**Platform:** iOS 17+ (targeting iOS 18+ features)  
**Estimated Effort:** 10-12 weeks (solo developer)  
**Last Updated:** November 2025

### Technical Vision

Kapture is built as a native iOS app using SwiftUI, following Apple's Human Interface Guidelines to create a fast, elegant, and deeply integrated experience. The architecture prioritizes performance (sub-second launch), offline-first functionality, and seamless Notion API integration.

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   SwiftUI    │  │  WidgetKit   │  │   Share      │ │
│  │    Views     │  │   Widgets    │  │  Extension   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  ViewModel Layer (MVVM)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Capture     │  │  Database    │  │    Sync     │ │
│  │  ViewModel   │  │  ViewModel   │  │  ViewModel  │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   Business Logic Layer                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Notion     │  │   Sync       │  │   Smart     │ │
│  │   Service    │  │   Service    │  │   Router    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   SwiftData  │  │   Keychain    │  │   User      │ │
│  │  (Local DB)  │  │  (Tokens)    │  │  Defaults   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  External Services                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Notion API (REST)                        │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Architecture Pattern: MVVM with Combine

**Why MVVM:**
- Separation of concerns (Views, ViewModels, Models)
- Testable business logic
- Reactive data flow with Combine
- SwiftUI-friendly pattern
- Scalable for future features

**Key Principles:**
- **Views:** Pure SwiftUI views, no business logic
- **ViewModels:** ObservableObject, manages state and business logic
- **Models:** Swift structs/classes, Codable for API
- **Services:** Singleton services for Notion API, sync, storage
- **Repositories:** Data access abstraction layer

---

## Tech Stack Decision

### Core Framework

#### SwiftUI (iOS 17+)
- **Why:** Native, declarative UI framework
- **Benefits:** 
  - Fast development
  - Native performance
  - Automatic dark mode support
  - Built-in animations
- **Version:** iOS 17+ minimum, iOS 18+ for widget features

#### Swift 5.9+
- **Why:** Latest Swift features, async/await, modern concurrency
- **Features Used:**
  - async/await for networking
  - Actors for thread safety
  - Swift Concurrency for background tasks

### Data Layer

#### SwiftData (iOS 17+)
- **Why:** Modern, Swift-native persistence framework
- **Benefits:**
  - Type-safe models
  - SwiftUI integration
  - Automatic migrations
  - Simpler than Core Data
- **Alternative:** Core Data if SwiftData limitations encountered

#### Keychain Services
- **Why:** Secure token storage
- **Implementation:** Using KeychainAccess wrapper for convenience

#### UserDefaults
- **Why:** Simple preferences storage
- **Use Cases:** User preferences, app settings, sync preferences

### Networking

#### URLSession (Native)
- **Why:** Native, powerful, no dependencies
- **Features:**
  - async/await support
  - Background tasks
  - Certificate pinning capability
- **Wrapper:** Custom NotionAPIClient wrapper

### Widgets

#### WidgetKit (iOS 18+)
- **Why:** Native widget framework
- **Features:**
  - Lock screen widgets
  - Home screen widgets
  - Interactive widgets (iOS 18+)
  - Widget extensions

### State Management

#### Combine Framework
- **Why:** Native reactive framework
- **Use Cases:**
  - ViewModel state management
  - Network request handling
  - Data flow between layers
  - Error handling

### Development Tools

#### Xcode 15+
- **IDE:** Primary development environment
- **Features:** SwiftUI previews, debugging, profiling

#### Cursor 2.0
- **AI Assistant:** Code generation, architecture help
- **Usage:** AI-assisted development workflow

#### Swift Package Manager
- **Dependency Management:** Native, no external tools needed

### Third-Party Dependencies

**Minimal Dependencies:**
- KeychainAccess (convenience wrapper for Keychain)
- Potentially: Notion Swift SDK (if available) or custom implementation

**Avoid:**
- Heavy networking libraries (use URLSession)
- Complex state management (use Combine)
- UI component libraries (use native SwiftUI)

---

## Component Design

### Project Structure

```
Kapture/
├── Kapture/
│   ├── App/
│   │   ├── KaptureApp.swift           # App entry point
│   │   └── AppDelegate.swift          # App lifecycle
│   │
│   ├── Views/
│   │   ├── Authentication/
│   │   │   ├── WelcomeView.swift
│   │   │   ├── NotionAuthView.swift
│   │   │   └── ConnectionStatusView.swift
│   │   │
│   │   ├── Capture/
│   │   │   ├── CaptureView.swift      # Main capture interface
│   │   │   ├── DatabaseSelectorView.swift
│   │   │   ├── PropertyInputView.swift
│   │   │   └── PropertyInputComponents/
│   │   │       ├── TextPropertyView.swift
│   │   │       ├── DatePropertyView.swift
│   │   │       ├── SelectPropertyView.swift
│   │   │       └── ...
│   │   │
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   ├── DatabasePreferencesView.swift
│   │   │   └── SyncSettingsView.swift
│   │   │
│   │   └── Common/
│   │       ├── LoadingView.swift
│   │       ├── ErrorView.swift
│   │       └── EmptyStateView.swift
│   │
│   ├── ViewModels/
│   │   ├── CaptureViewModel.swift
│   │   ├── DatabaseListViewModel.swift
│   │   ├── SyncViewModel.swift
│   │   └── SettingsViewModel.swift
│   │
│   ├── Models/
│   │   ├── Notion/
│   │   │   ├── NotionDatabase.swift
│   │   │   ├── NotionPage.swift
│   │   │   ├── NotionProperty.swift
│   │   │   └── NotionPropertyTypes.swift
│   │   │
│   │   └── Local/
│   │       ├── CapturedEntry.swift
│   │       ├── SyncQueueItem.swift
│   │       └── DatabasePreference.swift
│   │
│   ├── Services/
│   │   ├── NotionService.swift        # Notion API client
│   │   ├── SyncService.swift          # Offline sync logic
│   │   ├── StorageService.swift       # SwiftData operations
│   │   ├── AuthService.swift          # OAuth & token management
│   │   └── SmartRouterService.swift   # Database suggestion logic
│   │
│   ├── Repositories/
│   │   ├── DatabaseRepository.swift
│   │   ├── EntryRepository.swift
│   │   └── SyncQueueRepository.swift
│   │
│   ├── Utilities/
│   │   ├── KeychainManager.swift
│   │   ├── NetworkMonitor.swift
│   │   ├── PerformanceMonitor.swift
│   │   └── Extensions/
│   │       ├── Date+Extensions.swift
│   │       └── String+Extensions.swift
│   │
│   └── Resources/
│       ├── Assets.xcassets
│       ├── Info.plist
│       └── LaunchScreen.storyboard
│
├── KaptureWidget/
│   ├── KaptureWidget.swift            # Widget extension
│   ├── WidgetViews/
│   │   ├── LockScreenWidgetView.swift
│   │   └── HomeScreenWidgetView.swift
│   └── WidgetModels/
│       └── WidgetEntry.swift
│
├── KaptureShareExtension/
│   ├── ShareViewController.swift
│   └── ShareViewModel.swift
│
└── Tests/
    ├── UnitTests/
    │   ├── ViewModels/
    │   ├── Services/
    │   └── Repositories/
    │
    └── UITests/
        └── CaptureFlowTests.swift
```

### Key Component Details

#### ViewModels (MVVM Pattern)

**CaptureViewModel:**
```swift
@MainActor
class CaptureViewModel: ObservableObject {
    @Published var selectedDatabase: NotionDatabase?
    @Published var propertyValues: [String: Any] = [:]
    @Published var isCapturing: Bool = false
    @Published var captureError: Error?
    
    private let notionService: NotionService
    private let syncService: SyncService
    private let smartRouter: SmartRouterService
    
    func loadSuggestedDatabase() async
    func captureEntry() async throws
    func updateProperty(_ propertyId: String, value: Any)
}
```

**DatabaseListViewModel:**
```swift
@MainActor
class DatabaseListViewModel: ObservableObject {
    @Published var databases: [NotionDatabase] = []
    @Published var recentDatabases: [NotionDatabase] = []
    @Published var isLoading: Bool = false
    
    private let databaseRepository: DatabaseRepository
    
    func loadDatabases() async throws
    func refreshDatabases() async throws
    func markAsRecent(_ database: NotionDatabase)
}
```

#### Services

**NotionService:**
```swift
actor NotionService {
    private let apiClient: NotionAPIClient
    private let tokenManager: AuthService
    
    func authenticate() async throws -> OAuthResult
    func fetchDatabases() async throws -> [NotionDatabase]
    func createPage(in databaseId: String, properties: [String: Any]) async throws -> NotionPage
    func fetchDatabaseSchema(_ databaseId: String) async throws -> DatabaseSchema
}
```

**SyncService:**
```swift
actor SyncService {
    private let storageService: StorageService
    private let notionService: NotionService
    
    func syncPendingEntries() async throws
    func queueEntryForSync(_ entry: CapturedEntry) async
    func resolveConflict(_ entry: CapturedEntry, _ remoteEntry: NotionPage) async throws
}
```

---

## Database Schema

### SwiftData Models

#### CapturedEntry (Local Storage)

```swift
import SwiftData

@Model
final class CapturedEntry {
    var id: UUID
    var notionDatabaseId: String
    var notionDatabaseName: String
    var properties: Data // JSON encoded property values
    var createdAt: Date
    var syncedAt: Date?
    var syncStatus: SyncStatus
    var syncError: String?
    var retryCount: Int
    
    init(
        id: UUID = UUID(),
        notionDatabaseId: String,
        notionDatabaseName: String,
        properties: [String: Any],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.notionDatabaseId = notionDatabaseId
        self.notionDatabaseName = notionDatabaseName
        self.properties = try! JSONEncoder().encode(properties)
        self.createdAt = createdAt
        self.syncStatus = .pending
        self.retryCount = 0
    }
}

enum SyncStatus: String, Codable {
    case pending
    case syncing
    case synced
    case failed
    case conflict
}
```

#### DatabasePreference (User Preferences)

```swift
@Model
final class DatabasePreference {
    var databaseId: String
    var isFavorite: Bool
    var lastUsedAt: Date
    var usageCount: Int
    var preferredCaptureTime: DateComponents? // e.g., 9:00 AM
    
    init(databaseId: String) {
        self.databaseId = databaseId
        self.isFavorite = false
        self.lastUsedAt = Date()
        self.usageCount = 0
    }
}
```

#### SyncQueueItem (Sync Management)

```swift
@Model
final class SyncQueueItem {
    var entryId: UUID
    var queuedAt: Date
    var attemptCount: Int
    var nextRetryAt: Date?
    var errorMessage: String?
    
    init(entryId: UUID) {
        self.entryId = entryId
        self.queuedAt = Date()
        self.attemptCount = 0
    }
}
```

### SwiftData Configuration

```swift
import SwiftData

let modelConfiguration = ModelConfiguration(
    schema: Schema([
        CapturedEntry.self,
        DatabasePreference.self,
        SyncQueueItem.self
    ]),
    isStoredInMemoryOnly: false
)

let modelContainer = try ModelContainer(
    for: CapturedEntry.self,
    DatabasePreference.self,
    SyncQueueItem.self,
    configurations: modelConfiguration
)
```

---

## Feature Implementation

### Feature 1: Notion Authentication & Connection

#### OAuth 2.0 Flow Implementation

```swift
class AuthService {
    private let keychain: KeychainManager
    private let notionAPIClient: NotionAPIClient
    
    func startOAuthFlow() async throws -> URL {
        // Generate OAuth URL with redirect URI
        let authURL = notionAPIClient.buildOAuthURL(
            clientId: Config.notionClientId,
            redirectURI: Config.redirectURI,
            responseType: "code"
        )
        return authURL
    }
    
    func handleOAuthCallback(_ url: URL) async throws {
        // Extract authorization code
        guard let code = extractCode(from: url) else {
            throw AuthError.invalidCallback
        }
        
        // Exchange code for access token
        let tokenResponse = try await notionAPIClient.exchangeCodeForToken(code)
        
        // Store tokens securely
        try keychain.store(tokenResponse.accessToken, for: .notionAccessToken)
        if let refreshToken = tokenResponse.refreshToken {
            try keychain.store(refreshToken, for: .notionRefreshToken)
        }
    }
    
    func refreshTokenIfNeeded() async throws {
        guard let refreshToken = try? keychain.retrieve(.notionRefreshToken) else {
            throw AuthError.notAuthenticated
        }
        
        let newToken = try await notionAPIClient.refreshToken(refreshToken)
        try keychain.store(newToken.accessToken, for: .notionAccessToken)
    }
}
```

#### Notion API Client

```swift
actor NotionAPIClient {
    private let baseURL = "https://api.notion.com/v1"
    private let tokenManager: AuthService
    
    func fetchDatabases() async throws -> [NotionDatabase] {
        let token = try await tokenManager.getValidToken()
        
        var request = URLRequest(url: URL(string: "\(baseURL)/search")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["filter": ["property": "object", "value": "database"]]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NotionAPIError.requestFailed
        }
        
        let result = try JSONDecoder().decode(NotionSearchResponse.self, from: data)
        return result.results.compactMap { NotionDatabase.from($0) }
    }
    
    func createPage(databaseId: String, properties: [String: Any]) async throws -> NotionPage {
        // Implementation for creating Notion page
    }
}
```

---

### Feature 2: Zero-Setup Quick Capture

#### Performance Optimization

**App Launch Optimization:**
```swift
@main
struct KaptureApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // Pre-load critical resources
        preloadCriticalResources()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // Lazy load non-critical components
                    loadNonCriticalComponents()
                }
        }
    }
    
    private func preloadCriticalResources() {
        // Load token from Keychain (fast)
        // Initialize minimal UI state
        // Skip heavy network calls
    }
}
```

**Lazy Loading Strategy:**
```swift
struct CaptureView: View {
    @StateObject private var viewModel = CaptureViewModel()
    @State private var isLoadingDatabases = false
    
    var body: some View {
        VStack {
            if isLoadingDatabases {
                ProgressView()
            } else {
                CaptureForm(viewModel: viewModel)
            }
        }
        .task {
            // Load in background
            await loadDatabases()
        }
    }
    
    private func loadDatabases() async {
        isLoadingDatabases = true
        defer { isLoadingDatabases = false }
        
        // Use cached databases first
        if let cached = await viewModel.getCachedDatabases() {
            viewModel.databases = cached
        }
        
        // Then refresh in background
        try? await viewModel.loadDatabases()
    }
}
```

---

### Feature 3: Comprehensive Database Support

#### Database Discovery

```swift
class DatabaseRepository {
    private let notionService: NotionService
    private let storageService: StorageService
    
    func discoverDatabases() async throws -> [NotionDatabase] {
        // Fetch top-level databases
        let topLevel = try await notionService.fetchDatabases()
        
        // Fetch inline databases from pages
        let inlineDatabases = try await discoverInlineDatabases()
        
        return topLevel + inlineDatabases
    }
    
    private func discoverInlineDatabases() async throws -> [NotionDatabase] {
        // Search for pages with inline databases
        let pages = try await notionService.searchPages(
            filter: ["property": "type", "value": "page"]
        )
        
        var inlineDatabases: [NotionDatabase] = []
        
        for page in pages {
            if let databases = try? await notionService.fetchInlineDatabases(from: page.id) {
                inlineDatabases.append(contentsOf: databases)
            }
        }
        
        return inlineDatabases
    }
}
```

---

### Feature 4: Complete Property Type Support

#### Property Input Components

**Text Property:**
```swift
struct TextPropertyView: View {
    let property: NotionProperty
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(property.name)
                .font(.headline)
            
            if property.type == .richText {
                TextEditor(text: $value)
                    .frame(minHeight: 100)
            } else {
                TextField("Enter \(property.name)", text: $value)
            }
        }
    }
}
```

**Date Property:**
```swift
struct DatePropertyView: View {
    let property: NotionProperty
    @Binding var value: Date?
    @State private var showPicker = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(property.name)
                .font(.headline)
            
            Button(action: { showPicker.toggle() }) {
                HStack {
                    Text(value?.formatted(date: .abbreviated, time: .shortened) ?? "Select date")
                    Spacer()
                    Image(systemName: "calendar")
                }
            }
            .sheet(isPresented: $showPicker) {
                DatePicker(
                    property.name,
                    selection: Binding(
                        get: { value ?? Date() },
                        set: { value = $0 }
                    ),
                    displayedComponents: property.includesTime ? [.date, .hourAndMinute] : [.date]
                )
                .datePickerStyle(.graphical)
            }
        }
    }
}
```

**Select Property:**
```swift
struct SelectPropertyView: View {
    let property: NotionProperty
    @Binding var value: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(property.name)
                .font(.headline)
            
            Picker(property.name, selection: $value) {
                Text("None").tag(nil as String?)
                ForEach(property.options ?? [], id: \.id) { option in
                    Text(option.name).tag(option.id as String?)
                }
            }
            .pickerStyle(.menu)
        }
    }
}
```

---

### Feature 5: Offline-First Architecture

#### Sync Service Implementation

```swift
actor SyncService {
    private let storageService: StorageService
    private let notionService: NotionService
    private let networkMonitor: NetworkMonitor
    
    func syncPendingEntries() async throws {
        guard networkMonitor.isConnected else {
            return // Skip sync if offline
        }
        
        let pendingEntries = try await storageService.fetchPendingEntries()
        
        for entry in pendingEntries {
            do {
                try await syncEntry(entry)
                try await storageService.markAsSynced(entry.id)
            } catch {
                try await handleSyncError(entry, error: error)
            }
        }
    }
    
    private func syncEntry(_ entry: CapturedEntry) async throws {
        let properties = try JSONDecoder().decode([String: Any].self, from: entry.properties)
        
        _ = try await notionService.createPage(
            databaseId: entry.notionDatabaseId,
            properties: properties
        )
    }
    
    private func handleSyncError(_ entry: CapturedEntry, error: Error) async throws {
        entry.retryCount += 1
        
        if entry.retryCount < 3 {
            // Exponential backoff
            let delay = pow(2.0, Double(entry.retryCount))
            try await storageService.scheduleRetry(entry.id, delay: delay)
        } else {
            try await storageService.markAsFailed(entry.id, error: error)
        }
    }
}
```

#### Background Sync

```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Schedule background sync
        scheduleBackgroundSync()
        return true
    }
    
    func scheduleBackgroundSync() {
        let identifier = "com.kapture.sync"
        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // 1 minute
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        // Handle background sync completion
        Task {
            try? await SyncService.shared.syncPendingEntries()
            completionHandler()
        }
    }
}
```

---

### Feature 6: iOS Widget Integration

#### Widget Implementation

```swift
import WidgetKit

struct KaptureWidget: Widget {
    let kind: String = "KaptureWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KaptureTimelineProvider()) { entry in
            KaptureWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Capture")
        .description("Capture entries to Notion instantly")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct KaptureTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> KaptureEntry {
        KaptureEntry(date: Date(), recentDatabases: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (KaptureEntry) -> Void) {
        let entry = KaptureEntry(date: Date(), recentDatabases: loadRecentDatabases())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<KaptureEntry>) -> Void) {
        let entry = KaptureEntry(date: Date(), recentDatabases: loadRecentDatabases())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadRecentDatabases() -> [Database] {
        // Load from shared UserDefaults or App Group
        // Return recent databases
    }
}

struct KaptureWidgetView: View {
    var entry: KaptureEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Quick Capture")
                .font(.headline)
            
            ForEach(entry.recentDatabases.prefix(3)) { database in
                Button(intent: CaptureIntent(databaseId: database.id)) {
                    HStack {
                        Text(database.name)
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
}
```

#### App Intent (iOS 18+)

```swift
@available(iOS 17.0, *)
struct CaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture Entry"
    
    @Parameter(title: "Database ID")
    var databaseId: String
    
    func perform() async throws -> some IntentResult {
        // Open app with database pre-selected
        await openApp(with: databaseId)
        return .result()
    }
    
    private func openApp(with databaseId: String) async {
        // Use URL scheme to open app
        if let url = URL(string: "kapture://capture?databaseId=\(databaseId)") {
            await UIApplication.shared.open(url)
        }
    }
}
```

---

### Feature 7: Smart Database Routing

#### Smart Router Implementation

```swift
class SmartRouterService {
    private let databaseRepository: DatabaseRepository
    private let storageService: StorageService
    
    func suggestDatabase(for time: Date = Date()) async -> NotionDatabase? {
        // Get user's capture patterns
        let patterns = try? await storageService.fetchCapturePatterns()
        
        // Analyze patterns
        let hour = Calendar.current.component(.hour, from: time)
        let weekday = Calendar.current.component(.weekday, from: time)
        
        // Find matching pattern
        if let pattern = patterns?.first(where: { pattern in
            pattern.hourRange.contains(hour) && pattern.weekdays.contains(weekday)
        }) {
            return try? await databaseRepository.fetchDatabase(id: pattern.databaseId)
        }
        
        // Fallback: most recently used
        return try? await databaseRepository.fetchMostRecentDatabase()
    }
    
    func recordCapture(databaseId: String, timestamp: Date) async {
        let hour = Calendar.current.component(.hour, from: timestamp)
        let weekday = Calendar.current.component(.weekday, from: timestamp)
        
        try? await storageService.recordCapturePattern(
            databaseId: databaseId,
            hour: hour,
            weekday: weekday
        )
    }
}
```

---

## Security Implementation

### Token Storage

```swift
class KeychainManager {
    private let service = "com.kapture.notion"
    
    func store(_ token: String, for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed
        }
    }
    
    func retrieve(_ key: KeychainKey) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        
        return token
    }
}

enum KeychainKey: String {
    case notionAccessToken
    case notionRefreshToken
}
```

### Network Security

```swift
class NetworkSecurity {
    static func configureURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        
        // Certificate pinning (if needed)
        configuration.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024)
        
        // Timeout configuration
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        return URLSession(configuration: configuration)
    }
}
```

---

## Performance Optimization

### Launch Time Optimization

**Target:** < 500ms cold start

**Strategies:**
1. **Minimize App Launch Work:**
   - Defer non-critical initialization
   - Use lazy loading for heavy components
   - Cache critical data (tokens, recent databases)

2. **Optimize SwiftUI Views:**
   - Use `@State` instead of `@StateObject` when possible
   - Minimize view hierarchy depth
   - Use `LazyVStack` for lists

3. **Background Processing:**
   - Move network calls to background
   - Use async/await for concurrent operations
   - Prefetch data when app is backgrounded

### Capture Performance

**Target:** < 2 seconds total capture time

**Optimizations:**
```swift
// Parallel property loading
func loadCaptureForm() async {
    async let database = loadDatabase()
    async let schema = loadSchema()
    
    let (db, sch) = try await (database, schema)
    // Render form
}

// Optimistic UI updates
func captureEntry() async {
    // Save locally immediately
    try await storageService.saveLocally(entry)
    
    // Sync in background
    Task.detached {
        try? await syncService.sync(entry)
    }
}
```

### Memory Management

```swift
// Use weak references for closures
class CaptureViewModel: ObservableObject {
    private weak var delegate: CaptureDelegate?
    
    // Release resources when not needed
    deinit {
        cancelAllTasks()
    }
}

// Image caching
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    func image(for url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
}
```

---

## Development Workflow

### AI-Assisted Development Strategy

| Phase | Primary Tool | Purpose |
|-------|--------------|---------|
| **Architecture** | Cursor 2.0 | System design, component structure |
| **Implementation** | Cursor 2.0 | Code generation, SwiftUI views |
| **Debugging** | Cursor 2.0 + Xcode | Error fixing, performance profiling |
| **Testing** | Xcode XCTest | Unit tests, UI tests |
| **Documentation** | Cursor 2.0 | Code comments, README |

### Git Workflow

```bash
main
├── develop
│   ├── feature/notion-auth
│   ├── feature/quick-capture
│   ├── feature/widgets
│   ├── feature/offline-sync
│   └── fix/[bug-description]
└── release/v1.0.0
```

### Development Environment Setup

```bash
# 1. Clone repository
git clone [repo-url] Kapture
cd Kapture

# 2. Open in Xcode
open Kapture.xcodeproj

# 3. Install dependencies (if using SPM)
# Dependencies managed via Swift Package Manager

# 4. Configure Notion API credentials
# Add to Info.plist or Config.swift:
# - NOTION_CLIENT_ID
# - NOTION_CLIENT_SECRET
# - NOTION_REDIRECT_URI

# 5. Build and run
# ⌘R in Xcode
```

---

## Testing Strategy

### Unit Tests

**Target Coverage:** 70%+ for core logic

```swift
import XCTest
@testable import Kapture

class CaptureViewModelTests: XCTestCase {
    var viewModel: CaptureViewModel!
    var mockNotionService: MockNotionService!
    
    override func setUp() {
        super.setUp()
        mockNotionService = MockNotionService()
        viewModel = CaptureViewModel(notionService: mockNotionService)
    }
    
    func testCaptureEntry() async throws {
        // Given
        let properties = ["title": "Test Entry"]
        viewModel.propertyValues = properties
        
        // When
        try await viewModel.captureEntry()
        
        // Then
        XCTAssertTrue(mockNotionService.createPageCalled)
        XCTAssertEqual(viewModel.syncStatus, .synced)
    }
    
    func testOfflineCapture() async throws {
        // Given
        mockNotionService.isConnected = false
        
        // When
        try await viewModel.captureEntry()
        
        // Then
        XCTAssertEqual(viewModel.syncStatus, .pending)
        // Verify entry saved locally
    }
}
```

### UI Tests

```swift
import XCTest

class CaptureFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testQuickCaptureFlow() {
        // Launch app
        app.launch()
        
        // Select database
        let databaseButton = app.buttons["Select Database"]
        XCTAssertTrue(databaseButton.waitForExistence(timeout: 2))
        databaseButton.tap()
        
        // Select first database
        app.tables.firstMatch.cells.firstMatch.tap()
        
        // Fill property
        let textField = app.textFields["Title"]
        textField.tap()
        textField.typeText("Test Entry")
        
        // Capture
        app.buttons["Capture"].tap()
        
        // Verify success
        XCTAssertTrue(app.alerts["Success"].waitForExistence(timeout: 2))
    }
}
```

### Performance Tests

```swift
func testAppLaunchPerformance() {
    measure {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for main screen
        XCTAssertTrue(app.otherElements["CaptureView"].waitForExistence(timeout: 1))
    }
}
```

---

## Deployment

### App Store Preparation

**App Store Assets:**
- App Icon (1024x1024)
- Screenshots (6.7", 6.5", 5.5" displays)
- App Preview video (optional)
- Privacy Policy URL
- Support URL

**App Store Metadata:**
- App Name: "Kapture"
- Subtitle: "Fast Notion Capture"
- Description: [Based on PRD value proposition]
- Keywords: notion, capture, quick, productivity, database
- Category: Productivity

### Build Configuration

```swift
// Release configuration
#if DEBUG
let isDebug = true
let apiBaseURL = "https://api.notion.com/v1"
#else
let isDebug = false
let apiBaseURL = "https://api.notion.com/v1"
#endif
```

### TestFlight Beta Testing

1. Archive build in Xcode
2. Upload to App Store Connect
3. Add beta testers (minimum 10)
4. Collect feedback via TestFlight
5. Iterate based on feedback

### Release Checklist

- [ ] All P0 features implemented
- [ ] Unit test coverage > 70%
- [ ] UI tests passing
- [ ] Performance benchmarks met
- [ ] App Store assets prepared
- [ ] Privacy policy published
- [ ] Support contact method established
- [ ] Beta testing completed
- [ ] Crash reporting configured
- [ ] Analytics configured

---

## Cost Analysis

### Development Costs

| Resource | Cost | Notes |
|----------|------|-------|
| **Apple Developer Program** | $99/year | Required for App Store |
| **Development Tools** | $0 | Xcode free, Cursor pricing varies |
| **Notion API** | $0 | Free tier sufficient for MVP |
| **Testing Devices** | $0 | Use own iPhone |
| **Total Development** | **$99/year** | Minimal overhead |

### Operating Costs (Post-Launch)

| Service | Free Tier | Paid Tier | MVP Needs |
|---------|-----------|-----------|-----------|
| **Notion API** | Unlimited | N/A | Free tier |
| **App Store** | $99/year | Same | $99/year |
| **Analytics** | Free (optional) | $0-50/mo | Free tier |
| **Crash Reporting** | Free (optional) | $0-50/mo | Free tier |
| **Total Monthly** | **$0** | **$8.25/month** | **$0** |

### Scaling Costs (Future)

- **10,000 users:** Still within free tiers
- **100,000 users:** May need paid analytics/crash reporting (~$100/month)
- **1,000,000 users:** Consider dedicated infrastructure

---

## Risk Mitigation

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **Notion API changes** | Medium | High | Monitor API updates, version requests, maintain compatibility layer |
| **Performance targets not met** | Low | High | Profile early, optimize critical paths, use Instruments |
| **SwiftData limitations** | Medium | Medium | Have Core Data fallback plan, test thoroughly |
| **Widget complexity** | Medium | Low | Start with simple widgets, iterate |
| **Offline sync conflicts** | Medium | Medium | Implement robust conflict resolution, test edge cases |

### Development Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **Timeline delays** | Medium | High | MVP-first approach, cut P1 features if needed |
| **Technical complexity** | Medium | High | Prototype early, get feedback, simplify |
| **App Store rejection** | Low | High | Follow guidelines, test thoroughly, submit early |

---

## Migration & Scaling Path

### Phase 1: MVP (0-1K users)
- Current architecture handles well
- Monitor performance metrics
- Gather user feedback

### Phase 2: Growth (1K-10K users)
- Optimize database queries
- Add caching layer
- Improve sync efficiency

### Phase 3: Scale (10K+ users)
- Consider advanced caching strategies
- Optimize memory usage
- Add analytics for performance monitoring

---

## Documentation Requirements

- [ ] Architecture decision records (ADRs)
- [ ] API integration documentation
- [ ] Database schema documentation
- [ ] Sync algorithm documentation
- [ ] Widget implementation guide
- [ ] Performance optimization guide
- [ ] Deployment runbook
- [ ] Troubleshooting guide

---

**Technical Design Version:** 1.0  
**Status:** Draft - Ready for Implementation  
**Next Review:** After initial implementation  
**Owner:** Development Team  
**Last Updated:** November 2025

