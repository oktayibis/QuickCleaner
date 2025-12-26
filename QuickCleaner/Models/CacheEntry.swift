import Foundation

/// Types of cache locations
enum CacheType: String, CaseIterable, Codable {
    case browser = "Browser"
    case system = "System"
    case application = "Application"
    case developer = "Developer"
    case unknown = "Unknown"
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .browser: return "globe"
        case .system: return "gearshape"
        case .application: return "app"
        case .developer: return "hammer"
        case .unknown: return "questionmark.folder"
        }
    }
}

/// Represents a cache entry found during scanning
struct CacheEntry: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let name: String
    let size: UInt64
    let cacheType: CacheType
    let isDeveloperRelated: Bool
    let isSafeToDelete: Bool
    let description: String
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
}
