import SwiftUI

/// Navigation sidebar
struct Sidebar: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        @Bindable var state = appState
        
        List(selection: $state.currentSection) {
            Section {
                ForEach(NavSection.allCases) { section in
                    Button {
                        // Update the current section on tap to navigate
                        state.currentSection = section
                    } label: {
                        Label(section.rawValue, systemImage: section.iconName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .tag(section)
                    .badge(badgeText(for: section))
                    .contentShape(Rectangle())
                }
            } header: {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("Quick Cleaner")
                        .font(.headline)
                }
                .padding(.bottom, 8)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await appState.quickScan()
                    }
                } label: {
                    if appState.isScanning {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(appState.isScanning)
                .help("Quick Scan (⌘R)")
            }
        }
    }
    
    private func badgeText(for section: NavSection) -> Text? {
        let size: UInt64
        switch section {
        case .dashboard:
            return nil
        case .cache:
            size = appState.totalCacheSize
        case .developer:
            size = appState.totalDevCacheSize
        case .leftovers:
            size = appState.totalOrphanSize
        case .largeFiles:
            size = appState.totalLargeFilesSize
        case .duplicates:
            size = appState.totalDuplicateWasted
        }
        
        guard size > 0 else { return nil }
        return Text(ByteFormatter.formatCompact(size))
    }
}

#Preview {
    Sidebar()
        .environment(AppState())
        .frame(width: 220, height: 400)
}
