import SwiftUI

/// Leftover files view
struct LeftoverFilesView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedOrphans: Set<OrphanFile.ID> = []
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            if appState.isLoadingOrphans {
                loadingView
            } else if appState.orphanFiles.isEmpty {
                emptyView
            } else {
                orphanList
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .confirmationDialog(
            "Delete Selected Leftovers?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                Task {
                    await deleteSelectedOrphans()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will move \(selectedOrphans.count) leftover file(s) to Trash.")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Leftover Files")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(appState.orphanFiles.count) items • \(ByteFormatter.format(appState.totalOrphanSize))")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await appState.scanOrphanFiles()
                }
            } label: {
                Label("Scan", systemImage: "arrow.clockwise")
            }
            .disabled(appState.isLoadingOrphans)
            
            if !selectedOrphans.isEmpty {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
            }
        }
        .padding()
    }
    
    // MARK: - Orphan List
    
    private var orphanList: some View {
        List(selection: $selectedOrphans) {
            ForEach(OrphanType.allCases, id: \.self) { orphanType in
                let orphansOfType = appState.orphanFiles.filter { $0.orphanType == orphanType }
                if !orphansOfType.isEmpty {
                    Section {
                        ForEach(orphansOfType) { orphan in
                            OrphanRow(orphan: orphan) {
                                Task {
                                    await appState.deleteOrphan(orphan)
                                }
                            } onReveal: {
                                Task {
                                    await appState.revealInFinder(path: orphan.path)
                                }
                            }
                        }
                    } header: {
                        Label(orphanType.rawValue, systemImage: orphanType.iconName)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty/Loading Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Scanning for leftover files...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("No Leftover Files Found")
                .font(.headline)
            Text("Click 'Scan' to search for files from uninstalled apps.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func deleteSelectedOrphans() async {
        for id in selectedOrphans {
            if let orphan = appState.orphanFiles.first(where: { $0.id == id }) {
                await appState.deleteOrphan(orphan)
            }
        }
        selectedOrphans.removeAll()
    }
}

/// Orphan file row component
struct OrphanRow: View {
    let orphan: OrphanFile
    let onDelete: () -> Void
    let onReveal: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(orphan.name)
                    .font(.headline)
                Text("Possibly from: \(orphan.possibleAppName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(ByteFormatter.format(orphan.size))
                .font(.callout)
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
}

#Preview {
    LeftoverFilesView()
        .environment(AppState())
        .frame(width: 600, height: 400)
}
