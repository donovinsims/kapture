#if canImport(SwiftUI)
import SwiftUI

/// View for selecting a Notion database
struct DatabaseSelectorView: View {
    @StateObject private var viewModel = DatabaseListViewModel()
    @Binding var selectedDatabase: NotionDatabase?
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.databases.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.error != nil {
                    ErrorStateView(
                        error: viewModel.error,
                        retryAction: {
                            Task {
                                await viewModel.refreshDatabases()
                            }
                        }
                    )
                } else {
                    databaseList
                }
            }
            .navigationTitle("Select Database")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        Task {
                            await viewModel.refreshDatabases()
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search databases")
            .task {
                await viewModel.loadDatabases()
            }
        }
    }
    
    private var databaseList: some View {
        List {
            if !viewModel.recentDatabases.isEmpty {
                Section("Recent") {
                    ForEach(viewModel.recentDatabases) { database in
                        DatabaseRow(
                            database: database,
                            isSelected: selectedDatabase?.id == database.id,
                            isFavorite: viewModel.isFavorite(database),
                            onSelect: {
                                selectedDatabase = database
                                Task {
                                    await viewModel.markAsRecent(database)
                                }
                                dismiss()
                            },
                            onToggleFavorite: {
                                Task {
                                    await viewModel.toggleFavorite(database)
                                }
                            }
                        )
                    }
                }
            }
            
            if !viewModel.favoriteDatabases.isEmpty {
                Section("Favorites") {
                    ForEach(viewModel.favoriteDatabases) { database in
                        DatabaseRow(
                            database: database,
                            isSelected: selectedDatabase?.id == database.id,
                            isFavorite: true,
                            onSelect: {
                                selectedDatabase = database
                                Task {
                                    await viewModel.markAsRecent(database)
                                }
                                dismiss()
                            },
                            onToggleFavorite: {
                                Task {
                                    await viewModel.toggleFavorite(database)
                                }
                            }
                        )
                    }
                }
            }
            
            Section("All Databases") {
                ForEach(viewModel.filteredDatabases) { database in
                    DatabaseRow(
                        database: database,
                        isSelected: selectedDatabase?.id == database.id,
                        isFavorite: viewModel.isFavorite(database),
                        onSelect: {
                            selectedDatabase = database
                            Task {
                                await viewModel.markAsRecent(database)
                            }
                            dismiss()
                        },
                        onToggleFavorite: {
                            Task {
                                await viewModel.toggleFavorite(database)
                            }
                        }
                    )
                }
            }
        }
    }
}

/// Database row component
struct DatabaseRow: View {
    let database: NotionDatabase
    let isSelected: Bool
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Database icon
                if let icon = database.icon {
                    Text(icon)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "rectangle.grid.2x2")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                // Database title
                VStack(alignment: .leading, spacing: 4) {
                    Text(database.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let url = URL(string: database.url) {
                        Text(url.host ?? "")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
                
                // Favorite button
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

/// Error state view
struct ErrorStateView: View {
    let error: Error?
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Failed to load databases")
                .font(.system(size: 20, weight: .semibold))
            
            if let error = error {
                Text(error.localizedDescription)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DatabaseSelectorView(selectedDatabase: .constant(nil))
}

#endif

