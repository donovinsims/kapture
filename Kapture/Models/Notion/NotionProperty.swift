import Foundation

/// Represents a Notion property with its type and configuration
struct NotionProperty: Identifiable, Codable {
    let id: String
    let name: String
    let type: PropertyType
    let configuration: PropertyConfiguration?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        let typeString = try container.decode(String.self, forKey: .type)
        type = PropertyType(rawValue: typeString) ?? .unsupported
        
        // Decode configuration based on type
        configuration = try? PropertyConfiguration(from: decoder, type: type)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type.rawValue, forKey: .type)
        try configuration?.encode(to: encoder)
    }
}

/// Property types supported by Notion
enum PropertyType: String, Codable {
    case title
    case richText = "rich_text"
    case number
    case select
    case multiSelect = "multi_select"
    case date
    case people
    case files
    case checkbox
    case url
    case email
    case phoneNumber = "phone_number"
    case formula
    case relation
    case rollup
    case createdTime = "created_time"
    case createdBy = "created_by"
    case lastEditedTime = "last_edited_time"
    case lastEditedBy = "last_edited_by"
    case status
    case unsupported
    
    var isEditable: Bool {
        switch self {
        case .formula, .createdTime, .createdBy, .lastEditedTime, .lastEditedBy, .rollup:
            return false
        default:
            return true
        }
    }
}

/// Configuration for property types that need additional options
struct PropertyConfiguration: Codable {
    let selectOptions: [SelectOption]?
    let numberFormat: NumberFormat?
    let dateFormat: DateFormat?
    
    init(from decoder: Decoder, type: PropertyType) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        switch type {
        case .select, .multiSelect:
            selectOptions = try? container.decodeIfPresent([SelectOption].self, forKey: .selectOptions)
            numberFormat = nil
            dateFormat = nil
            
        case .number:
            selectOptions = nil
            numberFormat = try? container.decodeIfPresent(NumberFormat.self, forKey: .numberFormat)
            dateFormat = nil
            
        case .date:
            selectOptions = nil
            numberFormat = nil
            dateFormat = try? container.decodeIfPresent(DateFormat.self, forKey: .dateFormat)
            
        default:
            selectOptions = nil
            numberFormat = nil
            dateFormat = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case selectOptions = "select"
        case numberFormat = "number"
        case dateFormat = "date"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(selectOptions, forKey: .selectOptions)
        try container.encodeIfPresent(numberFormat, forKey: .numberFormat)
        try container.encodeIfPresent(dateFormat, forKey: .dateFormat)
    }
}

/// Select option for select/multi-select properties
struct SelectOption: Identifiable, Codable {
    let id: String
    let name: String
    let color: String?
}

/// Number format options
enum NumberFormat: String, Codable {
    case number
    case numberWithCommas = "number_with_commas"
    case percent
    case dollar
    case euro
    case pound
    case yen
    case ruble
}

/// Date format options
struct DateFormat: Codable {
    let format: String? // "MM/DD/YYYY", "DD/MM/YYYY", etc.
    let includeTime: Bool?
}

