import SwiftUI

/// Cache cleanup view
struct CacheCleanupView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedCaches: Set<CacheEntry.ID> = []
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            if appState.isLoadingCaches {
                loadingView
            } else if appState.caches.isEmpty {
                emptyView
            } else {
                cacheList
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .confirmationDialog(
            "Delete Selected Caches?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                Task {
                    await deleteSelectedCaches()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will move \(selectedCaches.count) cache(s) to Trash.")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cache Cleanup")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(appState.caches.count) items • \(ByteFormatter.format(appState.totalCacheSize))")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await appState.scanCaches()
                }
            } label: {
                Label("Scan", systemImage: "arrow.clockwise")
            }
            .disabled(appState.isLoadingCaches)
            
            if !selectedCaches.isEmpty {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
            }
        }
        .padding()
    }
    
    // MARK: - Cache List
    
    private var cacheList: some View {
        List(selection: $selectedCaches) {
            ForEach(CacheType.allCases, id: \.self) { cacheType in
                let cachesOfType = appState.caches.filter { $0.cacheType == cacheType }
                if !cachesOfType.isEmpty {
                    Section {
                        ForEach(cachesOfType) { cache in
                            CacheRow(cache: cache) {
                                Task {
                                    await appState.deleteCache(cache)
                                }
                            } onReveal: {
                                Task {
                                    await appState.revealInFinder(path: cache.path)
                                }
                            }
                        }
                    } header: {
                        Label(cacheType.displayName, systemImage: cacheType.iconName)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty/Loading Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Scanning caches...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("No Cache Files Found")
                .font(.headline)
            Text("Click 'Scan' to search for cache files.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func deleteSelectedCaches() async {
        for id in selectedCaches {
            if let cache = appState.caches.first(where: { $0.id == id }) {
                await appState.deleteCache(cache)
            }
        }
        selectedCaches.removeAll()
    }
}

/// Cache row component
struct CacheRow: View {
    let cache: CacheEntry
    let onDelete: () -> Void
    let onReveal: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(cache.name)
                    .font(.headline)
                Text(cache.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(ByteFormatter.format(cache.size))
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
    CacheCleanupView()
        .environment(AppState())
        .frame(width: 600, height: 400)
}
