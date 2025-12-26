import Foundation

/// Service for finding duplicate files
actor DuplicateScanner {
    static let shared = DuplicateScanner()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Collect URLs from enumerator synchronously to avoid Swift 6 async iterator issues
    private nonisolated func collectURLs(from enumerator: FileManager.DirectoryEnumerator) -> [URL] {
        var urls: [URL] = []
        for case let fileURL as URL in enumerator {
            urls.append(fileURL)
        }
        return urls
    }
    
    /// Scan a directory for duplicate files
    func scanDuplicates(in directory: String, minSizeMB: UInt64 = 1) async -> [DuplicateGroup] {
        let minSizeBytes = minSizeMB * 1024 * 1024
        let url = URL(fileURLWithPath: directory)
        
        // First pass: group files by size
        var filesBySize: [UInt64: [URL]] = [:]
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }
        
        // Collect URLs synchronously to avoid Swift 6 async iterator issues
        let fileURLs = collectURLs(from: enumerator)
        
        for fileURL in fileURLs {
            // Use autoreleasepool but avoid using 'continue' inside the closure
            var include = false
            var fileSizeValue: Int? = nil
            autoreleasepool {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                   resourceValues.isRegularFile == true,
                   let fileSize = resourceValues.fileSize,
                   UInt64(fileSize) >= minSizeBytes {
                    include = true
                    fileSizeValue = fileSize
                }
            }
            guard include, let fileSize = fileSizeValue else { continue }
            let size = UInt64(fileSize)
            filesBySize[size, default: []].append(fileURL)
        }
        
        // Second pass: hash files with matching sizes
        var duplicateGroups: [DuplicateGroup] = []
        
        for (size, files) in filesBySize {
            // Only consider files with the same size
            guard files.count > 1 else { continue }
            
            var filesByHash: [String: [URL]] = [:]
            
            for fileURL in files {
                if let hash = FileHasher.quickHash(for: fileURL) {
                    filesByHash[hash, default: []].append(fileURL)
                }
            }
            
            // Create groups for actual duplicates
            for (hash, duplicateFiles) in filesByHash {
                guard duplicateFiles.count > 1 else { continue }
                
                let group = DuplicateGroup(
                    hash: hash,
                    files: duplicateFiles.map { url in
                        DuplicateFile(path: url.path, name: url.lastPathComponent)
                    },
                    fileSize: size
                )
                
                duplicateGroups.append(group)
            }
        }
        
        return duplicateGroups.sorted { $0.totalWasted > $1.totalWasted }
    }
    
    /// Scan common directories for duplicates
    func scanCommonDirectories(minSizeMB: UInt64 = 1) async -> [DuplicateGroup] {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        let directories = [
            homeDir.appendingPathComponent("Downloads"),
            homeDir.appendingPathComponent("Documents"),
            homeDir.appendingPathComponent("Desktop"),
            homeDir.appendingPathComponent("Pictures"),
        ]
        
        // Collect all file hashes across directories
        var allFilesByHash: [String: [(url: URL, size: UInt64)]] = [:]
        let minSizeBytes = minSizeMB * 1024 * 1024
        
        for dir in directories {
            guard fileManager.fileExists(atPath: dir.path),
                  let enumerator = fileManager.enumerator(
                    at: dir,
                    includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                  ) else { continue }
            
            // Collect URLs synchronously to avoid Swift 6 async iterator issues
            let fileURLs = collectURLs(from: enumerator)
            
            for fileURL in fileURLs {
                var include = false
                var fileSizeValue: Int? = nil
                autoreleasepool {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                       resourceValues.isRegularFile == true,
                       let fileSize = resourceValues.fileSize,
                       UInt64(fileSize) >= minSizeBytes {
                        include = true
                        fileSizeValue = fileSize
                    }
                }
                guard include, let fileSize = fileSizeValue else { continue }
                if let hash = FileHasher.quickHash(for: fileURL) {
                    allFilesByHash[hash, default: []].append((url: fileURL, size: UInt64(fileSize)))
                }
            }
        }
        
        // Create duplicate groups
        var duplicateGroups: [DuplicateGroup] = []
        
        for (hash, files) in allFilesByHash {
            guard files.count > 1 else { continue }
            
            let size = files[0].size
            let group = DuplicateGroup(
                hash: hash,
                files: files.map { DuplicateFile(path: $0.url.path, name: $0.url.lastPathComponent) },
                fileSize: size
            )
            
            duplicateGroups.append(group)
        }
        
        return duplicateGroups.sorted { $0.totalWasted > $1.totalWasted }
    }
    
    /// Delete a duplicate file
    func deleteDuplicate(at path: String) async throws {
        try await FileOperations.shared.moveToTrash(path: path)
    }
    
    /// Get total wasted space from duplicates
    func getTotalWastedSpace(minSizeMB: UInt64 = 1) async -> UInt64 {
        let duplicates = await scanCommonDirectories(minSizeMB: minSizeMB)
        return duplicates.reduce(0) { $0 + $1.totalWasted }
    }
}
