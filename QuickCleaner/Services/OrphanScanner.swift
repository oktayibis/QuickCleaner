import Foundation

/// Service for detecting orphan files from uninstalled applications
actor OrphanScanner {
    static let shared = OrphanScanner()
    
    private let fileManager = FileManager.default
    private let fileOps = FileOperations.shared
    
    private init() {}
    
    /// Scan for installed applications
    func scanInstalledApps() async -> Set<String> {
        var appNames = Set<String>()
        
        let applicationsPaths = [
            URL(fileURLWithPath: "/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        
        for appsPath in applicationsPaths {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: appsPath,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for url in contents {
                if url.pathExtension == "app" {
                    let appName = url.deletingPathExtension().lastPathComponent
                    appNames.insert(appName.lowercased())
                    
                    // Also extract bundle ID if possible
                    if let bundleID = getBundleID(for: url) {
                        let components = bundleID.components(separatedBy: ".")
                        if let lastComponent = components.last {
                            appNames.insert(lastComponent.lowercased())
                        }
                    }
                }
            }
        }
        
        return appNames
    }
    
    /// Scan for orphan files from uninstalled apps
    func scanOrphanFiles() async -> [OrphanFile] {
        let installedApps = await scanInstalledApps()
        var orphans: [OrphanFile] = []
        
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        // Locations to scan for orphans
        let locations: [(path: String, type: OrphanType)] = [
            ("Library/Application Support", .applicationSupport),
            ("Library/Preferences", .preferences),
            ("Library/Containers", .containers),
            ("Library/Caches", .caches),
            ("Library/Logs", .logs),
        ]
        
        for (relativePath, orphanType) in locations {
            let locationPath = homeDir.appendingPathComponent(relativePath)
            
            guard let contents = try? fileManager.contentsOfDirectory(
                at: locationPath,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for itemURL in contents {
                let name = itemURL.lastPathComponent
                
                // Skip system and Apple items
                if isSystemItem(name: name) { continue }
                
                // Check if this matches an installed app
                let normalizedName = normalizeName(name)
                if installedApps.contains(where: { normalizedName.contains($0) || $0.contains(normalizedName) }) {
                    continue
                }
                
                // This appears to be an orphan
                let size = fileOps.getDirectorySizeSync(at: itemURL)
                
                orphans.append(OrphanFile(
                    path: itemURL.path,
                    name: name,
                    size: size,
                    orphanType: orphanType,
                    possibleAppName: extractAppName(from: name)
                ))
            }
        }
        
        return orphans.sorted { $0.size > $1.size }
    }
    
    /// Delete an orphan file or directory
    func deleteOrphan(at path: String) async throws {
        try await fileOps.moveToTrash(path: path)
    }
    
    // MARK: - Private Helpers
    
    private func getBundleID(for appURL: URL) -> String? {
        let infoPlistURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let bundleID = plist["CFBundleIdentifier"] as? String else {
            return nil
        }
        return bundleID
    }
    
    private func isSystemItem(name: String) -> Bool {
        let systemPrefixes = ["com.apple.", "Apple", ".", "System"]
        let systemNames = ["CloudDocs", "Mobile Documents", "Ubiquity", "CoreData", "GameKit"]
        
        let lowerName = name.lowercased()
        
        for prefix in systemPrefixes {
            if name.hasPrefix(prefix) || lowerName.hasPrefix(prefix.lowercased()) {
                return true
            }
        }
        
        return systemNames.contains(where: { name.contains($0) })
    }
    
    private func normalizeName(_ name: String) -> String {
        // Remove common suffixes and normalize
        var normalized = name.lowercased()
        
        // Remove bundle ID prefix patterns
        if normalized.hasPrefix("com.") {
            let components = normalized.components(separatedBy: ".")
            if components.count >= 2 {
                normalized = components.last ?? normalized
            }
        }
        
        // Remove version numbers and special characters
        normalized = normalized.replacingOccurrences(of: "[0-9._-]+", with: "", options: .regularExpression)
        
        return normalized.trimmingCharacters(in: .whitespaces)
    }
    
    private func extractAppName(from name: String) -> String {
        // Try to extract a readable app name from bundle ID or folder name
        var appName = name
        
        if name.hasPrefix("com.") || name.hasPrefix("org.") || name.hasPrefix("net.") {
            let components = name.components(separatedBy: ".")
            if components.count >= 3 {
                appName = components.dropFirst(2).joined(separator: " ")
            } else if let last = components.last {
                appName = last
            }
        }
        
        // Capitalize first letter of each word
        return appName.capitalized
    }
}
