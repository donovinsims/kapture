import XCTest
@testable import Kapture

/// Unit tests for PropertyValue conversion logic
final class PropertyValueTests: XCTestCase {
    
    // MARK: - Text Property Tests
    
    func testPropertyValue_ToNotionFormat_TextProperty() {
        // Given
        var propertyValue = PropertyValue()
        propertyValue.text = "Test Title"
        // Create property with PropertyType enum
        let property = NotionProperty(id: "title", name: "Title", type: .title, configuration: nil)
        
        // When
        let notionFormat = propertyValue.toNotionFormat(for: property)
        
        // Then
        XCTAssertFalse(notionFormat.isEmpty)
        XCTAssertNotNil(notionFormat["title"])
    }
    
    func testPropertyValue_ToNotionFormat_NumberProperty() {
        // Given
        var propertyValue = PropertyValue()
        propertyValue.number = 42.5
        let property = NotionProperty(id: "number", name: "Number", type: .number, configuration: nil)
        
        // When
        let notionFormat = propertyValue.toNotionFormat(for: property)
        
        // Then
        XCTAssertFalse(notionFormat.isEmpty)
        XCTAssertNotNil(notionFormat["number"])
    }
    
    func testPropertyValue_ToNotionFormat_CheckboxProperty() {
        // Given
        var propertyValue = PropertyValue()
        propertyValue.checkbox = true
        let property = NotionProperty(id: "checkbox", name: "Done", type: .checkbox, configuration: nil)
        
        // When
        let notionFormat = propertyValue.toNotionFormat(for: property)
        
        // Then
        XCTAssertFalse(notionFormat.isEmpty)
        XCTAssertNotNil(notionFormat["checkbox"])
    }
    
    func testPropertyValue_ToNotionFormat_DateProperty() {
        // Given
        var propertyValue = PropertyValue()
        propertyValue.date = Date()
        let property = NotionProperty(id: "date", name: "Date", type: .date, configuration: nil)
        
        // When
        let notionFormat = propertyValue.toNotionFormat(for: property)
        
        // Then
        XCTAssertFalse(notionFormat.isEmpty)
        XCTAssertNotNil(notionFormat["date"])
    }
    
    func testPropertyValue_ToNotionFormat_DateProperty_WhenNil_ReturnsEmpty() {
        // Given
        var propertyValue = PropertyValue()
        propertyValue.date = nil
        let property = NotionProperty(id: "date", name: "Date", type: .date, configuration: nil)
        
        // When
        let notionFormat = propertyValue.toNotionFormat(for: property)
        
        // Then
        XCTAssertTrue(notionFormat.isEmpty)
    }
    
    func testPropertyValue_ToNotionFormat_MultiSelectProperty() {
        // Given
        var propertyValue = PropertyValue()
        propertyValue.multiSelect = ["Tag1", "Tag2", "Tag3"]
        let property = NotionProperty(id: "tags", name: "Tags", type: .multiSelect, configuration: nil)
        
        // When
        let notionFormat = propertyValue.toNotionFormat(for: property)
        
        // Then
        XCTAssertFalse(notionFormat.isEmpty)
        XCTAssertNotNil(notionFormat["multi_select"])
    }
    
    func testPropertyValue_ToNotionFormat_URLProperty() {
        // Given
        var propertyValue = PropertyValue()
        propertyValue.url = "https://example.com"
        let property = NotionProperty(id: "url", name: "URL", type: .url, configuration: nil)
        
        // When
        let notionFormat = propertyValue.toNotionFormat(for: property)
        
        // Then
        XCTAssertFalse(notionFormat.isEmpty)
        XCTAssertEqual(notionFormat["url"] as? String, "https://example.com")
    }
}

