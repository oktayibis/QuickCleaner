import Foundation
import AppKit

/// File operations service for deleting and revealing files
actor FileOperations {
    static let shared = FileOperations()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Move a file or directory to Trash (safe deletion)
    func moveToTrash(path: String) async throws {
        let url = URL(fileURLWithPath: path)
        
        guard fileManager.fileExists(atPath: path) else {
            // Idempotent: already deleted
            return
        }
        
        var resultingItemURL: NSURL?
        try fileManager.trashItem(at: url, resultingItemURL: &resultingItemURL)
    }
    
    /// Permanently delete a file or directory
    func permanentlyDelete(path: String) async throws {
        guard fileManager.fileExists(atPath: path) else {
            // Idempotent: already deleted
            return
        }
        
        try fileManager.removeItem(atPath: path)
    }
    
    /// Reveal a file in Finder
    func revealInFinder(path: String) async {
        let url = URL(fileURLWithPath: path)
        await MainActor.run {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    
    /// Get the size of a directory (recursive)
    func getDirectorySize(at path: String) async -> UInt64 {
        let url = URL(fileURLWithPath: path)
        return getDirectorySizeSync(at: url)
    }
    
    /// Synchronous directory size calculation
    /// Uses totalFileAllocatedSizeKey to get actual disk usage (important for sparse files like Docker.raw)
    nonisolated func getDirectorySizeSync(at url: URL) -> UInt64 {
        let fileManager = FileManager.default
        var totalSize: UInt64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey, .isRegularFileKey]),
                  resourceValues.isRegularFile == true else {
                continue
            }
            // Prefer totalFileAllocatedSize (actual disk usage including sparse files),
            // fall back to fileAllocatedSize, then fileSize
            if let allocatedSize = resourceValues.totalFileAllocatedSize {
                totalSize += UInt64(allocatedSize)
            } else if let allocatedSize = resourceValues.fileAllocatedSize {
                totalSize += UInt64(allocatedSize)
            } else if let fileSize = resourceValues.fileSize {
                totalSize += UInt64(fileSize)
            }
        }
        
        return totalSize
    }
    
    /// Check if a path exists
    nonisolated func exists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}
