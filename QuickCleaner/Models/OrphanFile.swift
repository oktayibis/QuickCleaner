import Foundation

/// Types of orphan file locations
enum OrphanType: String, CaseIterable, Codable {
    case applicationSupport = "Application Support"
    case preferences = "Preferences"
    case containers = "Containers"
    case caches = "Caches"
    case logs = "Logs"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .applicationSupport: return "folder"
        case .preferences: return "gearshape.2"
        case .containers: return "shippingbox"
        case .caches: return "internaldrive"
        case .logs: return "doc.text"
        case .other: return "questionmark.folder"
        }
    }
}

/// Represents a leftover file from an uninstalled application
struct OrphanFile: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let name: String
    let size: UInt64
    let orphanType: OrphanType
    let possibleAppName: String
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
}
