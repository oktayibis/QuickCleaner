import Foundation

/// Categories of large files
enum FileCategory: String, CaseIterable, Codable {
    case video = "Video"
    case image = "Image"
    case audio = "Audio"
    case archive = "Archive"
    case document = "Document"
    case application = "Application"
    case diskImage = "Disk Image"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .video: return "film"
        case .image: return "photo"
        case .audio: return "music.note"
        case .archive: return "archivebox"
        case .document: return "doc"
        case .application: return "app"
        case .diskImage: return "externaldrive"
        case .other: return "doc.questionmark"
        }
    }
    
    var color: String {
        switch self {
        case .video: return "purple"
        case .image: return "green"
        case .audio: return "orange"
        case .archive: return "blue"
        case .document: return "gray"
        case .application: return "pink"
        case .diskImage: return "cyan"
        case .other: return "secondary"
        }
    }
    
    /// File extensions for each category
    static func category(for extension: String) -> FileCategory {
        let ext = `extension`.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v":
            return .video
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp", "raw", "psd":
            return .image
        case "mp3", "wav", "aac", "flac", "m4a", "ogg", "wma":
            return .audio
        case "zip", "rar", "7z", "tar", "gz", "bz2", "xz":
            return .archive
        case "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf":
            return .document
        case "app", "pkg", "ipa":
            return .application
        case "dmg", "iso", "img":
            return .diskImage
        default:
            return .other
        }
    }
}

/// Represents a large file found during scanning
struct LargeFile: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let name: String
    let size: UInt64
    let category: FileCategory
    let lastModified: Date?
    let fileExtension: String
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
}
