import Foundation

/// Service for scanning cache directories
actor CacheScanner {
    static let shared = CacheScanner()
    
    private let fileManager = FileManager.default
    private let fileOps = FileOperations.shared
    
    private init() {}
    
    /// Scan user caches (~Library/Caches)
    func scanUserCaches() async -> [CacheEntry] {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let cachesPath = homeDir.appendingPathComponent("Library/Caches")
        return await scanCacheDirectory(at: cachesPath)
    }
    
    /// Scan system caches (/Library/Caches)
    func scanSystemCaches() async -> [CacheEntry] {
        let systemCaches = URL(fileURLWithPath: "/Library/Caches")
        return await scanCacheDirectory(at: systemCaches, isSystem: true)
    }
    
    /// Scan all caches (user + system)
    func scanAllCaches() async -> [CacheEntry] {
        async let userCaches = scanUserCaches()
        async let systemCaches = scanSystemCaches()
        
        return await userCaches + systemCaches
    }
    
    /// Delete a cache entry
    func deleteCache(at path: String) async throws {
        try await fileOps.moveToTrash(path: path)
    }
    
    // MARK: - Private
    
    private func scanCacheDirectory(at url: URL, isSystem: Bool = false) async -> [CacheEntry] {
        var entries: [CacheEntry] = []
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        for itemURL in contents {
            let name = itemURL.lastPathComponent
            let path = itemURL.path
            let size = fileOps.getDirectorySizeSync(at: itemURL)
            
            // Determine cache type
            let cacheType = determineCacheType(name: name, isSystem: isSystem)
            let isDeveloperRelated = isDeveloperCache(name: name)
            let isSafe = isSafeToDelete(name: name)
            let description = generateDescription(name: name, cacheType: cacheType)
            
            entries.append(CacheEntry(
                path: path,
                name: name,
                size: size,
                cacheType: cacheType,
                isDeveloperRelated: isDeveloperRelated,
                isSafeToDelete: isSafe,
                description: description
            ))
        }
        
        return entries.sorted { $0.size > $1.size }
    }
    
    private func determineCacheType(name: String, isSystem: Bool) -> CacheType {
        let lowerName = name.lowercased()
        
        // Browser caches
        let browserKeywords = ["safari", "chrome", "firefox", "edge", "brave", "opera", "webkit"]
        if browserKeywords.contains(where: { lowerName.contains($0) }) {
            return .browser
        }
        
        // Developer related
        let devKeywords = ["xcode", "npm", "cargo", "gradle", "cocoapods", "homebrew", "pip", "composer"]
        if devKeywords.contains(where: { lowerName.contains($0) }) {
            return .developer
        }
        
        // System vs Application
        if isSystem {
            return .system
        }
        
        return .application
    }
    
    private func isDeveloperCache(name: String) -> Bool {
        let lowerName = name.lowercased()
        let devKeywords = ["xcode", "npm", "cargo", "gradle", "cocoapods", "homebrew", "pip", 
                           "composer", "maven", "android", "llvm", "clang", "swift"]
        return devKeywords.contains(where: { lowerName.contains($0) })
    }
    
    private func isSafeToDelete(name: String) -> Bool {
        // Most caches are safe to delete
        // Avoid system-critical caches
        let unsafeKeywords = ["apple", "system", "kernel"]
        let lowerName = name.lowercased()
        return !unsafeKeywords.contains(where: { lowerName.contains($0) })
    }
    
    private func generateDescription(name: String, cacheType: CacheType) -> String {
        switch cacheType {
        case .browser:
            return "Browser cache and temporary files"
        case .system:
            return "System cache files"
        case .developer:
            return "Developer tool cache"
        case .application:
            return "Application cache files"
        case .unknown:
            return "Cache files"
        }
    }
}
