import Foundation

/// Represents a single file in a duplicate group
struct DuplicateFile: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let name: String
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
}

/// Represents a group of duplicate files with the same hash
struct DuplicateGroup: Identifiable, Hashable {
    let id = UUID()
    let hash: String
    let files: [DuplicateFile]
    let fileSize: UInt64
    
    /// Total wasted space (all duplicates except one original)
    var totalWasted: UInt64 {
        guard files.count > 1 else { return 0 }
        return fileSize * UInt64(files.count - 1)
    }
    
    /// Number of duplicate copies (excluding original)
    var duplicateCount: Int {
        max(0, files.count - 1)
    }
}
