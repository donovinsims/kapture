import SwiftUI

/// Text property input component
struct TextPropertyView: View {
    @Binding var value: String
    let isMultiline: Bool
    
    init(value: Binding<String>, isMultiline: Bool = false) {
        self._value = value
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        if isMultiline {
            TextEditor(text: $value)
                .frame(minHeight: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        } else {
            TextField("Enter text", text: $value)
                .textFieldStyle(.roundedBorder)
        }
    }
}

/// Number property input component
struct NumberPropertyView: View {
    @Binding var value: Double?
    @State private var textValue: String = ""
    
    var body: some View {
        TextField("Enter number", text: $textValue)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .onChange(of: textValue) { newValue in
                value = Double(newValue)
            }
            .onAppear {
                if let value = value {
                    textValue = String(value)
                }
            }
    }
}

/// Date property input component
struct DatePropertyView: View {
    @Binding var value: Date?
    @State private var showPicker = false
    let includeTime: Bool
    
    init(value: Binding<Date?>, includeTime: Bool = false) {
        self._value = value
        self.includeTime = includeTime
    }
    
    var body: some View {
        Button(action: { showPicker.toggle() }) {
            HStack {
                Text(value?.formatted(date: .abbreviated, time: includeTime ? .shortened : .omitted) ?? "Select date")
                    .foregroundColor(value == nil ? .secondary : .primary)
                Spacer()
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showPicker) {
            NavigationView {
                DatePicker(
                    "Select date",
                    selection: Binding(
                        get: { value ?? Date() },
                        set: { value = $0 }
                    ),
                    displayedComponents: includeTime ? [.date, .hourAndMinute] : [.date]
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showPicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showPicker = false
                        }
                    }
                }
            }
        }
    }
}

/// Select property input component
struct SelectPropertyView: View {
    let property: NotionProperty
    @Binding var value: String?
    
    var body: some View {
        Picker(property.name, selection: $value) {
            Text("None").tag(nil as String?)
            if let options = property.configuration?.selectOptions {
                ForEach(options) { option in
                    Text(option.name).tag(option.name as String?)
                }
            }
        }
        .pickerStyle(.menu)
    }
}

/// Multi-select property input component
struct MultiSelectPropertyView: View {
    let property: NotionProperty
    @Binding var value: [String]
    
    var body: some View {
        let options = property.configuration?.selectOptions ?? []
        
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options) { option in
                HStack {
                    Button(action: {
                        if value.contains(option.name) {
                            value.removeAll { $0 == option.name }
                        } else {
                            value.append(option.name)
                        }
                    }) {
                        HStack {
                            Image(systemName: value.contains(option.name) ? "checkmark.square.fill" : "square")
                                .foregroundColor(value.contains(option.name) ? .blue : .secondary)
                            Text(option.name)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Checkbox property input component
struct CheckboxPropertyView: View {
    @Binding var value: Bool
    
    var body: some View {
        Toggle("", isOn: $value)
            .labelsHidden()
    }
}

/// URL property input component
struct URLPropertyView: View {
    @Binding var value: String
    
    var body: some View {
        TextField("https://", text: $value)
            .keyboardType(.URL)
            .textContentType(.URL)
            .autocapitalization(.none)
            .textFieldStyle(.roundedBorder)
    }
}

/// Email property input component
struct EmailPropertyView: View {
    @Binding var value: String
    
    var body: some View {
        TextField("email@example.com", text: $value)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocapitalization(.none)
            .textFieldStyle(.roundedBorder)
    }
}

/// Phone property input component
struct PhonePropertyView: View {
    @Binding var value: String
    
    var body: some View {
        TextField("(555) 123-4567", text: $value)
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
            .textFieldStyle(.roundedBorder)
    }
}

/// People property input component (placeholder)
struct PeoplePropertyView: View {
    @Binding var value: [String]
    
    var body: some View {
        Text("People selection not yet implemented")
            .foregroundColor(.secondary)
            .font(.system(size: 15))
    }
}

/// Unsupported property view
struct UnsupportedPropertyView: View {
    let propertyType: String
    
    var body: some View {
        Text("Property type '\(propertyType)' is not yet supported")
            .foregroundColor(.secondary)
            .font(.system(size: 15))
    }
}

