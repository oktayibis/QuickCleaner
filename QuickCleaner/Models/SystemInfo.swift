import Foundation

/// Disk usage information
struct DiskUsage: Hashable {
    let totalBytes: UInt64
    let freeBytes: UInt64
    let usedBytes: UInt64
    
    var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100.0
    }
    
    var freePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(freeBytes) / Double(totalBytes) * 100.0
    }
}

/// System information
struct SystemInfo {
    let osVersion: String
    let hostname: String
    let username: String
    let homeDirectory: String
    let diskUsage: DiskUsage
    
    static func current() -> SystemInfo {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser.path
        
        // Get disk usage
        let diskUsage = getDiskUsage()
        
        // Get OS version
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        
        // Get hostname
        let hostname = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        
        // Get username
        let username = ProcessInfo.processInfo.userName
        
        return SystemInfo(
            osVersion: osVersion,
            hostname: hostname,
            username: username,
            homeDirectory: homeDir,
            diskUsage: diskUsage
        )
    }
    
    private static func getDiskUsage() -> DiskUsage {
        let fileManager = FileManager.default
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: "/")
            let totalSize = attributes[.systemSize] as? UInt64 ?? 0
            let freeSize = attributes[.systemFreeSize] as? UInt64 ?? 0
            let usedSize = totalSize > freeSize ? totalSize - freeSize : 0
            
            return DiskUsage(
                totalBytes: totalSize,
                freeBytes: freeSize,
                usedBytes: usedSize
            )
        } catch {
            return DiskUsage(totalBytes: 0, freeBytes: 0, usedBytes: 0)
        }
    }
}
