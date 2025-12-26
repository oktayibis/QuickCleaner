import SwiftUI

/// Large files view
struct LargeFilesView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedFiles: Set<LargeFile.ID> = []
    @State private var showDeleteConfirmation = false
    @State private var selectedCategories: Set<FileCategory> = Set(FileCategory.allCases)
    
    var filteredFiles: [LargeFile] {
        appState.largeFiles.filter { selectedCategories.contains($0.category) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Filters
            filterBar
            
            Divider()
            
            // Content
            if appState.isLoadingLargeFiles {
                loadingView
            } else if filteredFiles.isEmpty {
                emptyView
            } else {
                fileList
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .confirmationDialog(
            "Delete Selected Files?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                Task {
                    await deleteSelectedFiles()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will move \(selectedFiles.count) file(s) to Trash.")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Large Files")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(filteredFiles.count) files • \(ByteFormatter.format(filteredFiles.reduce(0) { $0 + $1.size }))")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Size threshold
            HStack {
                Text("Min size:")
                    .foregroundStyle(.secondary)
                Picker("", selection: Binding(
                    get: { appState.largeFileSizeThreshold },
                    set: { appState.largeFileSizeThreshold = $0 }
                )) {
                    Text("10 MB").tag(UInt64(10))
                    Text("50 MB").tag(UInt64(50))
                    Text("100 MB").tag(UInt64(100))
                    Text("500 MB").tag(UInt64(500))
                    Text("1 GB").tag(UInt64(1024))
                }
                .frame(width: 100)
            }
            
            Button {
                Task {
                    await appState.scanLargeFiles()
                }
            } label: {
                Label("Scan", systemImage: "arrow.clockwise")
            }
            .disabled(appState.isLoadingLargeFiles)
            
            if !selectedFiles.isEmpty {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
            }
        }
        .padding()
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FileCategory.allCases, id: \.self) { category in
                    let count = appState.largeFiles.filter { $0.category == category }.count
                    FilterChip(
                        title: category.rawValue,
                        count: count,
                        isSelected: selectedCategories.contains(category)
                    ) {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - File List
    
    private var fileList: some View {
        List(selection: $selectedFiles) {
            ForEach(filteredFiles) { file in
                LargeFileRow(file: file) {
                    Task {
                        await appState.deleteLargeFile(file)
                    }
                } onReveal: {
                    Task {
                        await appState.revealInFinder(path: file.path)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty/Loading Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Scanning for large files...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Large Files Found")
                .font(.headline)
            Text("Click 'Scan' to search for large files, or adjust the filters.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func deleteSelectedFiles() async {
        for id in selectedFiles {
            if let file = appState.largeFiles.first(where: { $0.id == id }) {
                await appState.deleteLargeFile(file)
            }
        }
        selectedFiles.removeAll()
    }
}

/// Filter chip component
struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if count > 0 {
                    Text("(\(count))")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
            .foregroundStyle(isSelected ? .primary : .secondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Large file row component
struct LargeFileRow: View {
    let file: LargeFile
    let onDelete: () -> Void
    let onReveal: () -> Void
    
    var body: some View {
        HStack {
            // Category icon
            Image(systemName: file.category.iconName)
                .font(.title2)
                .foregroundStyle(categoryColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(file.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.15))
                        .foregroundStyle(categoryColor)
                        .clipShape(Capsule())
                    
                    if let date = file.lastModified {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            Text(ByteFormatter.format(file.size))
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            
            Button {
                onReveal()
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
            .help("Reveal in Finder")
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Move to Trash")
        }
        .padding(.vertical, 4)
    }
    
    private var categoryColor: Color {
        switch file.category {
        case .video: return .purple
        case .image: return .green
        case .audio: return .orange
        case .archive: return .blue
        case .document: return .gray
        case .application: return .pink
        case .diskImage: return .cyan
        case .other: return .secondary
        }
    }
}

#Preview {
    LargeFilesView()
        .environment(AppState())
        .frame(width: 700, height: 500)
}
