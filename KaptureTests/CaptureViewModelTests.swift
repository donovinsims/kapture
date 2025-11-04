import XCTest
@testable import Kapture

/// Unit tests for CaptureViewModel business logic
@MainActor
final class CaptureViewModelTests: XCTestCase {
    var viewModel: CaptureViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = CaptureViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Property Value Tests
    
    func testUpdateProperty_UpdatesValueCorrectly() {
        // Given
        let propertyId = "prop_123"
        var propertyValue = PropertyValue()
        propertyValue.text = "Test Value"
        
        // When
        viewModel.updateProperty(propertyId, value: propertyValue)
        
        // Then
        XCTAssertEqual(viewModel.propertyValues[propertyId]?.text, "Test Value")
    }
    
    func testUpdateProperty_OverwritesExistingValue() {
        // Given
        let propertyId = "prop_123"
        var initialValue = PropertyValue()
        initialValue.text = "Initial"
        viewModel.updateProperty(propertyId, value: initialValue)
        
        // When
        var newValue = PropertyValue()
        newValue.text = "Updated"
        viewModel.updateProperty(propertyId, value: newValue)
        
        // Then
        XCTAssertEqual(viewModel.propertyValues[propertyId]?.text, "Updated")
    }
    
    // MARK: - Capture Error Tests
    
    func testCaptureEntry_WithoutDatabase_ThrowsError() async {
        // Given
        viewModel.selectedDatabase = nil
        
        // When/Then
        do {
            try await viewModel.captureEntry()
            XCTFail("Should have thrown CaptureError.noDatabaseSelected")
        } catch {
            XCTAssertTrue(error is CaptureError)
            if case CaptureError.noDatabaseSelected = error {
                // Expected error
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
}

