import Foundation

/// Service for scanning developer tool caches
actor DeveloperScanner {
    static let shared = DeveloperScanner()
    
    private let fileManager = FileManager.default
    private let fileOps = FileOperations.shared
    
    private init() {}
    
    /// Scan all known developer cache locations
    func scanDeveloperCaches() async -> [DeveloperCache] {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        var caches: [DeveloperCache] = []
        
        // Scan known locations
        for location in DeveloperCache.knownLocations {
            let path = homeDir.appendingPathComponent(location.relativePath)
            let exists = fileManager.fileExists(atPath: path.path)
            let size: UInt64 = exists ? fileOps.getDirectorySizeSync(at: path) : 0
            
            caches.append(DeveloperCache(
                name: location.name,
                path: path.path,
                size: size,
                description: location.description,
                exists: exists,
                safeToClean: location.safeToClean
            ))
        }
        
        // Check for Docker Desktop
        let dockerPath = homeDir
            .appendingPathComponent("Library/Containers/com.docker.docker/Data")
        if fileManager.fileExists(atPath: dockerPath.path) {
            let size = fileOps.getDirectorySizeSync(at: dockerPath)
            caches.append(DeveloperCache(
                name: "Docker Desktop",
                path: dockerPath.path,
                size: size,
                description: "Docker Desktop data (use 'docker system prune' to clean)",
                exists: true,
                safeToClean: false
            ))
        }
        
        // Sort by size descending
        return caches.sorted { $0.size > $1.size }
    }
    
    /// Clean a developer cache (remove contents but keep directory)
    func cleanCache(at path: String) async throws -> UInt64 {
        let url = URL(fileURLWithPath: path)
        
        guard fileManager.fileExists(atPath: path) else {
            throw CleanerError.pathNotFound
        }
        
        // Don't allow cleaning Docker this way
        if path.contains("com.docker.docker") {
            throw CleanerError.dockerCleanNotAllowed
        }
        
        let sizeBefore = fileOps.getDirectorySizeSync(at: url)
        
        // Remove contents but keep the directory
        if let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: []
        ) {
            for item in contents {
                try fileManager.removeItem(at: item)
            }
        }
        
        return sizeBefore
    }
    
    /// Get total size of all developer caches
    func getTotalSize() async -> UInt64 {
        let caches = await scanDeveloperCaches()
        return caches.filter { $0.exists }.reduce(0) { $0 + $1.size }
    }
    
    /// Check if user is a developer (has dev tools installed)
    func isDeveloperUser() async -> Bool {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        let indicators = [
            homeDir.appendingPathComponent(".npm"),
            homeDir.appendingPathComponent(".cargo"),
            homeDir.appendingPathComponent(".gradle"),
            homeDir.appendingPathComponent("Library/Developer/Xcode"),
            homeDir.appendingPathComponent(".git"),
            URL(fileURLWithPath: "/Applications/Xcode.app"),
            URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
        ]
        
        for path in indicators {
            if fileManager.fileExists(atPath: path.path) {
                return true
            }
        }
        
        return false
    }
}

/// Cleaner-specific errors
enum CleanerError: LocalizedError {
    case pathNotFound
    case dockerCleanNotAllowed
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .pathNotFound:
            return "The specified path does not exist."
        case .dockerCleanNotAllowed:
            return "Please use 'docker system prune' command or Docker Desktop UI to clean Docker data."
        case .accessDenied:
            return "Access denied. Full Disk Access permission may be required."
        }
    }
}
