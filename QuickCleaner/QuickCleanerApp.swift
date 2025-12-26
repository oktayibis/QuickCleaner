import SwiftUI

/// Main app entry point
@main
struct QuickCleanerApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    appState.loadSystemInfo()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Scan") {
                Button("Quick Scan") {
                    Task {
                        await appState.quickScan()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])
                
                Divider()
                
                Button("Scan Caches") {
                    Task { await appState.scanCaches() }
                }
                
                Button("Scan Developer Tools") {
                    Task { await appState.scanDeveloperCaches() }
                }
                
                Button("Scan Leftovers") {
                    Task { await appState.scanOrphanFiles() }
                }
                
                Button("Scan Large Files") {
                    Task { await appState.scanLargeFiles() }
                }
                
                Button("Scan Duplicates") {
                    Task { await appState.scanDuplicates() }
                }
            }
        }
    }
}
