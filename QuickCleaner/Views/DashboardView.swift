import SwiftUI
import Charts

/// Dashboard view showing overview and quick actions
struct DashboardView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Disk Usage
                diskUsageSection
                
                // Stats Grid
                statsGrid
                
                // Summary
                summarySection
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Overview of disk usage and cleanup opportunities")
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Disk Usage
    
    private var diskUsageSection: some View {
        HStack(spacing: 24) {
            // Pie Chart
            if let diskUsage = appState.systemInfo?.diskUsage {
                Chart {
                    SectorMark(
                        angle: .value("Used", diskUsage.usedPercentage),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(.purple.gradient)
                    
                    SectorMark(
                        angle: .value("Free", diskUsage.freePercentage),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(NSColor.controlBackgroundColor))
                }
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "internaldrive")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Disk Storage")
                    .font(.headline)
                
                if let diskUsage = appState.systemInfo?.diskUsage {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(ByteFormatter.format(diskUsage.freeBytes))
                            .font(.title)
                            .fontWeight(.bold)
                        Text("available of \(ByteFormatter.format(diskUsage.totalBytes))")
                            .foregroundStyle(.secondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(NSColor.controlBackgroundColor))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor(for: diskUsage.usedPercentage))
                                .frame(width: geo.size.width * diskUsage.usedPercentage / 100)
                        }
                    }
                    .frame(width: 300, height: 8)
                    
                    // Legend
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.purple)
                                .frame(width: 8, height: 8)
                            Text("Used: \(ByteFormatter.format(diskUsage.usedBytes))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(NSColor.controlBackgroundColor))
                                .frame(width: 8, height: 8)
                            Text("Free: \(ByteFormatter.format(diskUsage.freeBytes))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Loading disk information...")
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Quick Scan Button
            Button {
                Task {
                    await appState.quickScan()
                }
            } label: {
                HStack {
                    if appState.isScanning {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(appState.isScanning ? "Scanning..." : "Quick Scan")
                }
                .frame(width: 120)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(appState.isScanning)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage > 90 {
            return .red
        } else if percentage > 70 {
            return .orange
        } else {
            return .purple
        }
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                icon: "internaldrive",
                title: "Cache Files",
                value: ByteFormatter.format(appState.totalCacheSize),
                color: .blue,
                isLoading: appState.isLoadingCaches
            ) {
                appState.currentSection = .cache
            }
            
            StatCard(
                icon: "hammer",
                title: "Developer Cache",
                value: ByteFormatter.format(appState.totalDevCacheSize),
                color: .green,
                isLoading: appState.isLoadingDeveloperCaches
            ) {
                appState.currentSection = .developer
            }
            
            StatCard(
                icon: "folder.badge.questionmark",
                title: "Leftover Files",
                value: ByteFormatter.format(appState.totalOrphanSize),
                color: .orange,
                isLoading: appState.isLoadingOrphans
            ) {
                appState.currentSection = .leftovers
            }
            
            StatCard(
                icon: "doc.richtext",
                title: "Large Files",
                value: ByteFormatter.format(appState.totalLargeFilesSize),
                color: .pink,
                isLoading: appState.isLoadingLargeFiles
            ) {
                appState.currentSection = .largeFiles
            }
            
            StatCard(
                icon: "doc.on.doc",
                title: "Duplicate Waste",
                value: ByteFormatter.format(appState.totalDuplicateWasted),
                color: .purple,
                isLoading: appState.isLoadingDuplicates
            ) {
                appState.currentSection = .duplicates
            }
        }
    }
    
    // MARK: - Summary
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cleanup Summary")
                .font(.headline)
            
            if appState.totalPotentialSavings > 0 {
                Text("Found potential savings of \(ByteFormatter.format(appState.totalPotentialSavings))")
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Badge(text: "\(appState.caches.count) cache items", color: .blue)
                    Badge(text: "\(appState.developerCaches.filter { $0.exists }.count) dev caches", color: .green)
                    Badge(text: "\(appState.orphanFiles.count) orphan files", color: .orange)
                    Badge(text: "\(appState.largeFiles.count) large files", color: .pink)
                    Badge(text: "\(appState.duplicates.count) duplicate groups", color: .purple)
                }
            } else {
                Text("Run a quick scan to find cleanup opportunities")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

/// Stat card component
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Badge component
struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
        .frame(width: 700, height: 600)
}
