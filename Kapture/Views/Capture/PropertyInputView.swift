import SwiftUI

/// Main view for inputting property values
struct PropertyInputView: View {
    let property: NotionProperty
    @Binding var value: PropertyValue
    @State private var internalValue: PropertyValue
    
    init(property: NotionProperty, value: Binding<PropertyValue>) {
        self.property = property
        self._value = value
        self._internalValue = State(initialValue: value.wrappedValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(property.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
            
            Group {
                switch property.type {
                case .title, .richText:
                    TextPropertyView(value: $internalValue.text)
                case .number:
                    NumberPropertyView(value: $internalValue.number)
                case .date:
                    DatePropertyView(value: $internalValue.date)
                case .select:
                    SelectPropertyView(property: property, value: $internalValue.select)
                case .multiSelect:
                    MultiSelectPropertyView(property: property, value: $internalValue.multiSelect)
                case .checkbox:
                    CheckboxPropertyView(value: $internalValue.checkbox)
                case .url:
                    URLPropertyView(value: $internalValue.url)
                case .email:
                    EmailPropertyView(value: $internalValue.email)
                case .phoneNumber:
                    PhonePropertyView(value: $internalValue.phone)
                case .people:
                    PeoplePropertyView(value: $internalValue.people)
                default:
                    UnsupportedPropertyView(propertyType: property.type.rawValue)
                }
            }
            .onChange(of: internalValue) { newValue in
                value = newValue
            }
        }
        .padding(.vertical, 8)
    }
}

/// Value holder for property inputs
struct PropertyValue: Equatable {
    var text: String = ""
    var number: Double?
    var date: Date?
    var select: String?
    var multiSelect: [String] = []
    var checkbox: Bool = false
    var url: String = ""
    var email: String = ""
    var phone: String = ""
    var people: [String] = []
    
    /// Converts to Notion API format
    func toNotionFormat(for property: NotionProperty) -> [String: Any] {
        switch property.type {
        case .title:
            return ["title": [["text": ["content": text]]]]
        case .richText:
            return ["rich_text": [["text": ["content": text]]]]
        case .number:
            return ["number": number ?? 0]
        case .date:
            if let date = date {
                return ["date": ["start": ISO8601DateFormatter().string(from: date)]]
            }
            return [:]
        case .select:
            return ["select": ["name": select ?? ""]]
        case .multiSelect:
            return ["multi_select": multiSelect.map { ["name": $0] }]
        case .checkbox:
            return ["checkbox": checkbox]
        case .url:
            return ["url": url]
        case .email:
            return ["email": email]
        case .phoneNumber:
            return ["phone_number": phone]
        case .people:
            return ["people": people.map { ["id": $0] }]
        default:
            return [:]
        }
    }
}

