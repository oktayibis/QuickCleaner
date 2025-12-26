import Foundation
import SwiftUI

/// Navigation sections in the app
enum NavSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard = "Dashboard"
    case cache = "Cache Cleanup"
    case developer = "Developer Tools"
    case leftovers = "Leftover Files"
    case largeFiles = "Large Files"
    case duplicates = "Duplicates"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.bottom.50percent"
        case .cache: return "internaldrive"
        case .developer: return "hammer"
        case .leftovers: return "folder.badge.questionmark"
        case .largeFiles: return "doc.richtext"
        case .duplicates: return "doc.on.doc"
        }
    }
}

/// Main application state
@MainActor
@Observable
final class AppState {
    // Navigation
    var currentSection: NavSection = .dashboard
    
    // System info
    var systemInfo: SystemInfo?
    
    // Cache data
    var caches: [CacheEntry] = []
    var isLoadingCaches = false
    
    // Developer caches
    var developerCaches: [DeveloperCache] = []
    var isLoadingDeveloperCaches = false
    
    // Orphan files
    var orphanFiles: [OrphanFile] = []
    var isLoadingOrphans = false
    
    // Large files
    var largeFiles: [LargeFile] = []
    var isLoadingLargeFiles = false
    var largeFileSizeThreshold: UInt64 = 100 // MB
    
    // Duplicates
    var duplicates: [DuplicateGroup] = []
    var isLoadingDuplicates = false
    var duplicateMinSize: UInt64 = 1 // MB
    
    // Errors
    var lastError: String?
    var showError = false
    
    // MARK: - Computed Properties
    
    var isScanning: Bool {
        isLoadingCaches || isLoadingDeveloperCaches || isLoadingOrphans || 
        isLoadingLargeFiles || isLoadingDuplicates
    }
    
    var totalCacheSize: UInt64 {
        caches.reduce(0) { $0 + $1.size }
    }
    
    var totalDevCacheSize: UInt64 {
        developerCaches.filter { $0.exists }.reduce(0) { $0 + $1.size }
    }
    
    var totalOrphanSize: UInt64 {
        orphanFiles.reduce(0) { $0 + $1.size }
    }
    
    var totalLargeFilesSize: UInt64 {
        largeFiles.reduce(0) { $0 + $1.size }
    }
    
    var totalDuplicateWasted: UInt64 {
        duplicates.reduce(0) { $0 + $1.totalWasted }
    }
    
    var totalPotentialSavings: UInt64 {
        totalCacheSize + totalDevCacheSize + totalOrphanSize + totalDuplicateWasted
    }
    
    // MARK: - Actions
    
    func loadSystemInfo() {
        systemInfo = SystemInfo.current()
    }
    
    func scanCaches() async {
        isLoadingCaches = true
        defer { isLoadingCaches = false }
        
        caches = await CacheScanner.shared.scanAllCaches()
    }
    
    func scanDeveloperCaches() async {
        isLoadingDeveloperCaches = true
        defer { isLoadingDeveloperCaches = false }
        
        developerCaches = await DeveloperScanner.shared.scanDeveloperCaches()
    }
    
    func scanOrphanFiles() async {
        isLoadingOrphans = true
        defer { isLoadingOrphans = false }
        
        orphanFiles = await OrphanScanner.shared.scanOrphanFiles()
    }
    
    func scanLargeFiles() async {
        isLoadingLargeFiles = true
        defer { isLoadingLargeFiles = false }
        
        largeFiles = await LargeFileScanner.shared.scanCommonDirectories(minSizeMB: largeFileSizeThreshold)
    }
    
    func scanDuplicates() async {
        isLoadingDuplicates = true
        defer { isLoadingDuplicates = false }
        
        duplicates = await DuplicateScanner.shared.scanCommonDirectories(minSizeMB: duplicateMinSize)
    }
    
    func quickScan() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.scanCaches() }
            group.addTask { await self.scanDeveloperCaches() }
            group.addTask { await self.scanOrphanFiles() }
            group.addTask { await self.scanLargeFiles() }
            group.addTask { await self.scanDuplicates() }
        }
    }
    
    // MARK: - Delete Operations
    
    func deleteCache(_ cache: CacheEntry) async {
        do {
            try await CacheScanner.shared.deleteCache(at: cache.path)
            caches.removeAll { $0.id == cache.id }
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func cleanDeveloperCache(_ cache: DeveloperCache) async {
        do {
            _ = try await DeveloperScanner.shared.cleanCache(at: cache.path)
            // Refresh the list
            await scanDeveloperCaches()
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func deleteOrphan(_ orphan: OrphanFile) async {
        do {
            try await OrphanScanner.shared.deleteOrphan(at: orphan.path)
            orphanFiles.removeAll { $0.id == orphan.id }
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func deleteLargeFile(_ file: LargeFile) async {
        do {
            try await LargeFileScanner.shared.deleteFile(at: file.path)
            largeFiles.removeAll { $0.id == file.id }
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func deleteDuplicate(_ file: DuplicateFile, from group: DuplicateGroup) async {
        do {
            try await DuplicateScanner.shared.deleteDuplicate(at: file.path)
            
            // Update the group
            if let groupIndex = duplicates.firstIndex(where: { $0.id == group.id }) {
                var updatedFiles = duplicates[groupIndex].files
                updatedFiles.removeAll { $0.id == file.id }
                
                if updatedFiles.count <= 1 {
                    // No more duplicates in this group
                    duplicates.remove(at: groupIndex)
                } else {
                    duplicates[groupIndex] = DuplicateGroup(
                        hash: group.hash,
                        files: updatedFiles,
                        fileSize: group.fileSize
                    )
                }
            }
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func revealInFinder(path: String) async {
        await FileOperations.shared.revealInFinder(path: path)
    }
    
    // MARK: - Private
    
    private func showError(_ message: String) {
        lastError = message
        showError = true
    }
}

