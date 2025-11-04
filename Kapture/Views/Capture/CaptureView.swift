import SwiftUI

/// Main capture interface view
struct CaptureView: View {
    @StateObject private var viewModel = CaptureViewModel()
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.selectedDatabase == nil {
                    emptyStateView
                } else {
                    captureFormView
                }
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.showDatabaseSelector = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.grid.2x2")
                            if let database = viewModel.selectedDatabase {
                                Text(database.title)
                                    .lineLimit(1)
                                    .frame(maxWidth: 100)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showDatabaseSelector) {
                DatabaseSelectorView(selectedDatabase: Binding(
                    get: { viewModel.selectedDatabase },
                    set: { database in
                        if let database = database {
                            Task {
                                await viewModel.selectDatabase(database)
                            }
                        }
                    }
                ))
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    showSuccessAlert = false
                }
            } message: {
                Text("Entry captured successfully!")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.captureError != nil },
                set: { if !$0 { viewModel.captureError = nil } }
            )) {
                Button("OK") {
                    viewModel.captureError = nil
                }
            } message: {
                if let error = viewModel.captureError {
                    Text(error.localizedDescription)
                }
            }
            .task {
                await viewModel.loadSuggestedDatabase()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.grid.2x2")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Select a Database")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Choose a Notion database to start capturing entries")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.showDatabaseSelector = true
            }) {
                Text("Select Database")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var captureFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let database = viewModel.selectedDatabase {
                    // Database header
                    HStack {
                        if let icon = database.icon {
                            Text(icon)
                                .font(.system(size: 24))
                        }
                        Text(database.title)
                            .font(.system(size: 20, weight: .semibold))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                // Property inputs
                if viewModel.isLoadingSchema {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let database = viewModel.selectedDatabase,
                          let properties = database.properties {
                    ForEach(Array(properties.values).sorted(by: { $0.name < $1.name }), id: \.id) { property in
                        if property.type.isEditable {
                            PropertyInputView(
                                property: property,
                                value: Binding(
                                    get: { viewModel.propertyValues[property.id] ?? PropertyValue() },
                                    set: { viewModel.updateProperty(property.id, value: $0) }
                                )
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Capture button
                Button(action: {
                    Task {
                        do {
                            try await viewModel.captureEntry()
                            showSuccessAlert = true
                        } catch {
                            // Error handled by viewModel
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isCapturing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(viewModel.isCapturing ? "Capturing..." : "Capture")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.isCapturing ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isCapturing)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

#Preview {
    CaptureView()
}
