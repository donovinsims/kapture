import Foundation

/// Represents a Notion database
struct NotionDatabase: Identifiable, Codable {
    let id: String
    let title: String
    let icon: String?
    let url: String
    let createdTime: Date?
    let lastEditedTime: Date?
    let properties: [String: NotionProperty]?
    let parent: DatabaseParent?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case icon
        case url
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case properties
        case parent
    }
    
    /// Creates a NotionDatabase from raw API response
    static func from(_ raw: NotionDatabaseRaw) -> NotionDatabase? {
        guard let id = raw.id else { return nil }
        
        // Extract title from title array
        let title = extractTitle(from: raw.title)
        
        return NotionDatabase(
            id: id,
            title: title,
            icon: raw.icon?.emoji,
            url: raw.url ?? "",
            createdTime: parseDate(raw.createdTime),
            lastEditedTime: parseDate(raw.lastEditedTime),
            properties: raw.properties,
            parent: raw.parent
        )
    }
    
    private static func extractTitle(from titleArray: [TitleRichText]?) -> String {
        guard let titleArray = titleArray else { return "Untitled" }
        
        let titleParts = titleArray.compactMap { $0.plainText }
        let joinedTitle = titleParts.joined(separator: " ")
        
        return joinedTitle.isEmpty ? "Untitled" : joinedTitle
    }
    
    private static func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try parsing with fractional seconds first
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Fallback: try without fractional seconds
        let dateWithoutFractional = dateString.replacingOccurrences(
            of: "\\.\\d+",
            with: "",
            options: .regularExpression
        )
        return formatter.date(from: dateWithoutFractional)
    }
}

/// Raw database response from Notion API
struct NotionDatabaseRaw: Codable {
    let id: String?
    let title: [TitleRichText]?
    let icon: DatabaseIcon?
    let url: String?
    let createdTime: String?
    let lastEditedTime: String?
    let properties: [String: NotionProperty]?
    let parent: DatabaseParent?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case icon
        case url
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case properties
        case parent
    }
}

/// Title rich text structure
struct TitleRichText: Codable {
    let plainText: String?
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
        case type
    }
}

/// Database icon representation
struct DatabaseIcon: Codable {
    let emoji: String?
    let type: String?
}

/// Database parent (can be workspace or page)
struct DatabaseParent: Codable {
    let type: String
    let workspaceId: String?
    let pageId: String?
}

/// Notion page (placeholder - will be expanded)
struct NotionPage: Codable {
    let id: String
    let url: String?
    let createdTime: Date?
    let lastEditedTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case url
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
    }
}

