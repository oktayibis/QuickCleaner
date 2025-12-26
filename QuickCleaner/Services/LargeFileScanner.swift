import Foundation

/// Service for scanning large files
actor LargeFileScanner {
    static let shared = LargeFileScanner()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Scan a directory for large files
    func scanLargeFiles(
        in directory: String,
        minSizeMB: UInt64 = 100,
        categories: [FileCategory]? = nil
    ) async -> [LargeFile] {
        let minSizeBytes = minSizeMB * 1024 * 1024
        let url = URL(fileURLWithPath: directory)
        var largeFiles: [LargeFile] = []
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }
        
        for case let fileURL as URL in enumerator {
            autoreleasepool {
                guard let resourceValues = try? fileURL.resourceValues(
                    forKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey]
                ),
                resourceValues.isRegularFile == true,
                let fileSize = resourceValues.fileSize,
                UInt64(fileSize) >= minSizeBytes else {
                    return
                }
                
                let ext = fileURL.pathExtension
                let category = FileCategory.category(for: ext)
                
                // Filter by category if specified
                if let allowedCategories = categories, !allowedCategories.contains(category) {
                    return
                }
                
                let largeFile = LargeFile(
                    path: fileURL.path,
                    name: fileURL.lastPathComponent,
                    size: UInt64(fileSize),
                    category: category,
                    lastModified: resourceValues.contentModificationDate,
                    fileExtension: ext
                )
                
                largeFiles.append(largeFile)
            }
        }
        
        return largeFiles.sorted { $0.size > $1.size }
    }
    
    /// Scan common directories for large files
    func scanCommonDirectories(minSizeMB: UInt64 = 100) async -> [LargeFile] {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        let directories = [
            homeDir.appendingPathComponent("Downloads"),
            homeDir.appendingPathComponent("Documents"),
            homeDir.appendingPathComponent("Desktop"),
            homeDir.appendingPathComponent("Movies"),
            homeDir.appendingPathComponent("Music"),
            homeDir.appendingPathComponent("Pictures"),
        ]
        
        var allFiles: [LargeFile] = []
        
        for dir in directories {
            if fileManager.fileExists(atPath: dir.path) {
                let files = await scanLargeFiles(in: dir.path, minSizeMB: minSizeMB)
                allFiles.append(contentsOf: files)
            }
        }
        
        return allFiles.sorted { $0.size > $1.size }
    }
    
    /// Delete a large file
    func deleteFile(at path: String) async throws {
        try await FileOperations.shared.moveToTrash(path: path)
    }
}
