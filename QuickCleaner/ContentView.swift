import SwiftUI

/// Main content view with sidebar navigation
struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationSplitView {
            Sidebar()
        } detail: {
            DetailView()
        }
        .alert("Error", isPresented: Binding(
            get: { appState.showError },
            set: { appState.showError = $0 }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appState.lastError ?? "An unknown error occurred")
        }
    }
}

/// Detail view based on current section
struct DetailView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        switch appState.currentSection {
        case .dashboard:
            DashboardView()
        case .cache:
            CacheCleanupView()
        case .developer:
            DeveloperToolsView()
        case .leftovers:
            LeftoverFilesView()
        case .largeFiles:
            LargeFilesView()
        case .duplicates:
            DuplicatesView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .frame(width: 900, height: 600)
}
