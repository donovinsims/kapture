import Foundation

/// Repository for managing Notion database operations.
/// Provides caching and efficient database discovery and retrieval.
actor DatabaseRepository {
    static let shared = DatabaseRepository()
    
    private let apiClient: NotionAPIClient
    private var cachedDatabases: [NotionDatabase] = []
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    private init() {
        self.apiClient = NotionAPIClient.shared
    }
    
    /// Discovers all accessible databases from Notion.
    /// - Returns: Array of NotionDatabase objects
    /// - Throws: Error if discovery fails
    func discoverDatabases() async throws -> [NotionDatabase] {
        // Fetch top-level databases
        let topLevel = try await apiClient.fetchDatabases()
        
        // Note: Inline database discovery may require additional API calls.
        // For MVP, focusing on top-level databases first.
        
        cachedDatabases = topLevel
        lastFetchTime = Date()
        
        return topLevel
    }
    
    /// Gets cached databases if available and fresh, otherwise fetches new ones.
    /// - Parameter forceRefresh: If true, bypasses cache and fetches fresh data
    /// - Returns: Array of NotionDatabase objects
    /// - Throws: Error if fetch fails
    func getDatabases(forceRefresh: Bool = false) async throws -> [NotionDatabase] {
        if !forceRefresh,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheTimeout {
            return cachedDatabases
        }
        
        return try await discoverDatabases()
    }
    
    /// Fetches a specific database by ID
    /// - Parameter databaseId: The ID of the database
    /// - Returns: NotionDatabase object
    /// - Throws: Error if fetch fails
    func fetchDatabase(id databaseId: String) async throws -> NotionDatabase {
        // First check cache
        if let cached = cachedDatabases.first(where: { $0.id == databaseId }) {
            return cached
        }
        
        // Fetch schema which includes database info
        let schema = try await apiClient.fetchDatabaseSchema(databaseId)
        return schema.database
    }
    
    /// Gets the most recently used database.
    /// - Returns: NotionDatabase or nil if none available
    /// Note: This will use DatabasePreference model when offline-sync is ready.
    /// For now, returns first cached database.
    func getMostRecentDatabase() async -> NotionDatabase? {
        return cachedDatabases.first
    }
    
    /// Clears the database cache
    func clearCache() {
        cachedDatabases = []
        lastFetchTime = nil
    }
}

