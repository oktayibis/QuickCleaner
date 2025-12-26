import Foundation

/// Utility for formatting byte sizes to human-readable strings
enum ByteFormatter {
    private static let units = ["B", "KB", "MB", "GB", "TB"]
    
    /// Format bytes to human-readable string (e.g., "1.5 GB")
    static func format(_ bytes: UInt64) -> String {
        var value = Double(bytes)
        var unitIndex = 0
        
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        if unitIndex == 0 {
            return "\(bytes) B"
        } else {
            return String(format: "%.2f %@", value, units[unitIndex])
        }
    }
    
    /// Format bytes with compact representation (e.g., "1.5GB")
    static func formatCompact(_ bytes: UInt64) -> String {
        var value = Double(bytes)
        var unitIndex = 0
        
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        if unitIndex == 0 {
            return "\(bytes)B"
        } else if value >= 100 {
            return String(format: "%.0f%@", value, units[unitIndex])
        } else if value >= 10 {
            return String(format: "%.1f%@", value, units[unitIndex])
        } else {
            return String(format: "%.2f%@", value, units[unitIndex])
        }
    }
}
