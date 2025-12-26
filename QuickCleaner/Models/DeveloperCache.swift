import Foundation

/// Represents a developer tool cache location
struct DeveloperCache: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let size: UInt64
    let description: String
    let exists: Bool
    let safeToClean: Bool
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
    
    /// Known developer cache locations
    static let knownLocations: [(name: String, relativePath: String, description: String, safeToClean: Bool)] = [
        ("npm Cache", ".npm", "Node.js package manager cache", true),
        ("Yarn Cache", ".yarn/cache", "Yarn package manager cache", true),
        ("pnpm Store", ".pnpm-store", "pnpm package manager store", true),
        ("Cargo Cache", ".cargo/registry/cache", "Rust package registry cache", true),
        ("CocoaPods Cache", "Library/Caches/CocoaPods", "iOS dependency manager cache", true),
        ("Xcode DerivedData", "Library/Developer/Xcode/DerivedData", "Xcode build artifacts (safe to clean)", true),
        ("Xcode Archives", "Library/Developer/Xcode/Archives", "Xcode archived builds", false),
        ("Gradle Cache", ".gradle/caches", "Android/Java build cache", true),
        ("Maven Repository", ".m2/repository", "Maven dependencies (partial clean recommended)", false),
        ("Homebrew Cache", "Library/Caches/Homebrew", "Homebrew package downloads", true),
        ("pip Cache", "Library/Caches/pip", "Python package cache", true),
        ("VS Code Cache", "Library/Application Support/Code/Cache", "Visual Studio Code cache", true),
        ("Android SDK Cache", "Library/Android/sdk/.temp", "Android SDK temporary files", true),
        ("Composer Cache", ".composer/cache", "PHP Composer package cache", true),
        ("Go Modules Cache", "go/pkg/mod/cache", "Go modules cache", true),
    ]
}
