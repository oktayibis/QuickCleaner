import SwiftUI

/// Duplicates view
struct DuplicatesView: View {
    @Environment(AppState.self) private var appState
    @State private var expandedGroups: Set<DuplicateGroup.ID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            if appState.isLoadingDuplicates {
                loadingView
            } else if appState.duplicates.isEmpty {
                emptyView
            } else {
                duplicateList
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Duplicate Files")
                    .font(.title2)
                    .fontWeight(.bold)
                
                let totalFiles = appState.duplicates.reduce(0) { $0 + $1.files.count }
                Text("\(appState.duplicates.count) groups • \(totalFiles) files • \(ByteFormatter.format(appState.totalDuplicateWasted)) wasted")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Min size
            HStack {
                Text("Min size:")
                    .foregroundStyle(.secondary)
                Picker("", selection: Binding(
                    get: { appState.duplicateMinSize },
                    set: { appState.duplicateMinSize = $0 }
                )) {
                    Text("1 MB").tag(UInt64(1))
                    Text("10 MB").tag(UInt64(10))
                    Text("50 MB").tag(UInt64(50))
                    Text("100 MB").tag(UInt64(100))
                }
                .frame(width: 100)
            }
            
            Button {
                Task {
                    await appState.scanDuplicates()
                }
            } label: {
                Label("Scan", systemImage: "arrow.clockwise")
            }
            .disabled(appState.isLoadingDuplicates)
        }
        .padding()
    }
    
    // MARK: - Duplicate List
    
    private var duplicateList: some View {
        List {
            ForEach(appState.duplicates) { group in
                DuplicateGroupRow(
                    group: group,
                    isExpanded: expandedGroups.contains(group.id),
                    onToggle: {
                        if expandedGroups.contains(group.id) {
                            expandedGroups.remove(group.id)
                        } else {
                            expandedGroups.insert(group.id)
                        }
                    },
                    onDeleteFile: { file in
                        Task {
                            await appState.deleteDuplicate(file, from: group)
                        }
                    },
                    onRevealFile: { file in
                        Task {
                            await appState.revealInFinder(path: file.path)
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Empty/Loading Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Scanning for duplicate files...")
                .foregroundStyle(.secondary)
            Text("This may take a while for large directories.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("No Duplicates Found")
                .font(.headline)
            Text("Click 'Scan' to search for duplicate files in common directories.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Duplicate group row component
struct DuplicateGroupRow: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDeleteFile: (DuplicateFile) -> Void
    let onRevealFile: (DuplicateFile) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Group header
            Button(action: onToggle) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    
                    Image(systemName: "doc.on.doc")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(group.files.count) identical files")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            Text("Each \(ByteFormatter.format(group.fileSize))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .foregroundStyle(.tertiary)
                            
                            Text("Wasted: \(ByteFormatter.format(group.totalWasted))")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            
            // Expanded file list
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(group.files.enumerated()), id: \.element.id) { index, file in
                        HStack {
                            // Original indicator
                            if index == 0 {
                                Text("Original")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.15))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            } else {
                                Text("Copy \(index)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.orange.opacity(0.15))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.name)
                                    .font(.callout)
                                    .lineLimit(1)
                                Text(file.path)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
                            Button {
                                onRevealFile(file)
                            } label: {
                                Image(systemName: "folder")
                            }
                            .buttonStyle(.borderless)
                            .help("Reveal in Finder")
                            
                            // Don't allow deleting the "original" (first file)
                            if index > 0 {
                                Button(role: .destructive) {
                                    onDeleteFile(file)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .help("Move to Trash")
                            }
                        }
                        .padding(.leading, 40)
                        .padding(.vertical, 6)
                        
                        if index < group.files.count - 1 {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.leading, 16)
                .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    DuplicatesView()
        .environment(AppState())
        .frame(width: 700, height: 500)
}
