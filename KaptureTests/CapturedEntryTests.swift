import XCTest
@testable import Kapture

/// Unit tests for CapturedEntry model
final class CapturedEntryTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testCapturedEntry_Initialization_CreatesWithDefaults() {
        // Given/When
        let entry = CapturedEntry(
            notionDatabaseId: "test_db",
            notionDatabaseName: "Test Database",
            properties: ["title": "Test"]
        )
        
        // Then
        XCTAssertEqual(entry.notionDatabaseId, "test_db")
        XCTAssertEqual(entry.notionDatabaseName, "Test Database")
        XCTAssertEqual(entry.syncStatus, .pending)
        XCTAssertEqual(entry.retryCount, 0)
        XCTAssertNil(entry.syncedAt)
    }
    
    func testCapturedEntry_EncodeDecodeProperties_RoundTrip() throws {
        // Given
        let properties: [String: Any] = [
            "title": "Test Title",
            "number": 42,
            "checkbox": true
        ]
        let entry = CapturedEntry(
            notionDatabaseId: "test_db",
            notionDatabaseName: "Test DB",
            properties: properties
        )
        
        // When
        let decoded = try entry.decodeProperties()
        
        // Then
        XCTAssertEqual(decoded["title"] as? String, "Test Title")
        XCTAssertEqual(decoded["number"] as? Int, 42)
        XCTAssertEqual(decoded["checkbox"] as? Bool, true)
    }
    
    func testCapturedEntry_DecodeProperties_WithInvalidData_ThrowsError() {
        // Given
        let entry = CapturedEntry(
            notionDatabaseId: "test_db",
            notionDatabaseName: "Test DB",
            properties: ["valid": "data"]
        )
        // Corrupt the data
        entry.properties = Data([0xFF, 0xFF, 0xFF])
        
        // When/Then
        XCTAssertThrowsError(try entry.decodeProperties()) { error in
            XCTAssertTrue(error is StorageError)
        }
    }
}

/// Unit tests for DatabasePreference model
final class DatabasePreferenceTests: XCTestCase {
    
    func testDatabasePreference_Initialization_CreatesWithDefaults() {
        // Given/When
        let preference = DatabasePreference(databaseId: "test_db")
        
        // Then
        XCTAssertEqual(preference.databaseId, "test_db")
        XCTAssertFalse(preference.isFavorite)
        XCTAssertEqual(preference.usageCount, 0)
    }
    
    func testDatabasePreference_RecordUsage_UpdatesCountAndDate() {
        // Given
        let preference = DatabasePreference(databaseId: "test_db")
        let initialCount = preference.usageCount
        let initialDate = preference.lastUsedAt
        
        // When
        // Wait a tiny bit to ensure time difference
        Thread.sleep(forTimeInterval: 0.01)
        preference.recordUsage()
        
        // Then
        XCTAssertEqual(preference.usageCount, initialCount + 1)
        XCTAssertGreaterThan(preference.lastUsedAt, initialDate)
    }
}

