import Foundation

/// Service for intelligent database suggestions based on usage patterns.
/// Learns from user behavior to suggest the most likely database for capture at different times.
actor SmartRouterService {
    static let shared = SmartRouterService()
    
    private let storageService: StorageService
    private let databaseRepository: DatabaseRepository
    
    private init() {
        self.storageService = StorageService.shared
        self.databaseRepository = DatabaseRepository.shared
    }
    
    /// Suggests the most likely database for capture at the given time
    /// - Parameter time: The time to check patterns for (defaults to now)
    /// - Returns: Suggested NotionDatabase or nil if no pattern matches
    func suggestDatabase(for time: Date = Date()) async -> NotionDatabase? {
        // Get user's capture patterns from preferences
        let preferences = try? await storageService.getRecentDatabases(limit: 20)
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        
        // Find databases used at similar times
        if let preferences = preferences {
            for preference in preferences {
                // Check if database was used at similar time
                let lastUsedHour = calendar.component(.hour, from: preference.lastUsedAt)
                let timeDiff = abs(hour - lastUsedHour)
                
                // If used within 2 hours of current time, suggest it
                if timeDiff <= 2 {
                    if let database = try? await databaseRepository.fetchDatabase(id: preference.databaseId) {
                        return database
                    }
                }
            }
        }
        
        // Fallback: most recently used database
        return await databaseRepository.getMostRecentDatabase()
    }
    
    /// Records a capture pattern for learning.
    /// - Parameters:
    ///   - databaseId: The database that was used
    ///   - timestamp: When the capture occurred
    func recordCapture(databaseId: String, timestamp: Date) async {
        do {
            // Record usage in preferences
            try await storageService.recordDatabaseUsage(databaseId: databaseId)
        } catch {
            // Silently fail - not critical for core functionality
        }
    }
    
    /// Gets suggested databases based on time of day
    /// - Parameter time: The time to check
    /// - Returns: Array of suggested databases sorted by relevance
    func getSuggestions(for time: Date = Date()) async -> [NotionDatabase] {
        let preferences = try? await storageService.getRecentDatabases(limit: 10)
        
        guard let preferences = preferences else {
            return []
        }
        
        var suggestions: [NotionDatabase] = []
        
        for preference in preferences {
            if let database = try? await databaseRepository.fetchDatabase(id: preference.databaseId) {
                suggestions.append(database)
            }
        }
        
        return suggestions
    }
}

