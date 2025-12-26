import SwiftUI

/// Developer tools cache view
struct DeveloperToolsView: View {
    @Environment(AppState.self) private var appState
    @State private var showCleanConfirmation = false
    @State private var cacheToClean: DeveloperCache?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            if appState.isLoadingDeveloperCaches {
                loadingView
            } else if appState.developerCaches.isEmpty {
                emptyView
            } else {
                cacheList
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .confirmationDialog(
            "Clean \(cacheToClean?.name ?? "Cache")?",
            isPresented: $showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clean", role: .destructive) {
                if let cache = cacheToClean {
                    Task {
                        await appState.cleanDeveloperCache(cache)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(cacheToClean?.description ?? "")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Developer Tools")
                    .font(.title2)
                    .fontWeight(.bold)
                
                let existingCaches = appState.developerCaches.filter { $0.exists }
                Text("\(existingCaches.count) detected • \(ByteFormatter.format(appState.totalDevCacheSize))")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await appState.scanDeveloperCaches()
                }
            } label: {
                Label("Scan", systemImage: "arrow.clockwise")
            }
            .disabled(appState.isLoadingDeveloperCaches)
        }
        .padding()
    }
    
    // MARK: - Cache List
    
    private var cacheList: some View {
        List {
            ForEach(appState.developerCaches) { cache in
                DeveloperCacheRow(cache: cache) {
                    cacheToClean = cache
                    showCleanConfirmation = true
                } onReveal: {
                    Task {
                        await appState.revealInFinder(path: cache.path)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty/Loading Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Scanning developer caches...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Developer Caches to Scan")
                .font(.headline)
            Text("Click 'Scan' to search for developer tool caches.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Developer cache row component
struct DeveloperCacheRow: View {
    let cache: DeveloperCache
    let onClean: () -> Void
    let onReveal: () -> Void
    
    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(cache.exists ? (cache.safeToClean ? .green : .orange) : .gray)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cache.name)
                    .font(.headline)
                    .foregroundStyle(cache.exists ? .primary : .secondary)
                Text(cache.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(cache.path)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            if cache.exists {
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
                
                if cache.safeToClean {
                    Button(role: .destructive) {
                        onClean()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Clean Cache")
                } else {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .help("Manual cleanup recommended")
                }
            } else {
                Text("Not Found")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .opacity(cache.exists ? 1 : 0.6)
    }
}

#Preview {
    DeveloperToolsView()
        .environment(AppState())
        .frame(width: 600, height: 400)
}
