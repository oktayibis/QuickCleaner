import Foundation
import CryptoKit

/// Utility for computing file hashes for duplicate detection
enum FileHasher {
    /// Hash chunk size for partial hashing (64KB)
    private static let chunkSize = 64 * 1024
    
    /// Compute a quick hash using file size + first and last chunks
    /// This is much faster than hashing entire files while still being accurate
    static func quickHash(for url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { try? handle.close() }
        
        // Get file size
        guard let size = try? handle.seekToEnd() else {
            return nil
        }
        
        var hasher = SHA256()
        
        // Add file size to hash
        var sizeBytes = size
        withUnsafeBytes(of: &sizeBytes) { hasher.update(bufferPointer: $0) }
        
        // Hash first chunk
        try? handle.seek(toOffset: 0)
        if let firstChunk = try? handle.read(upToCount: chunkSize) {
            hasher.update(data: firstChunk)
        }
        
        // Hash last chunk (if file is large enough)
        if size > UInt64(chunkSize * 2) {
            try? handle.seek(toOffset: size - UInt64(chunkSize))
            if let lastChunk = try? handle.read(upToCount: chunkSize) {
                hasher.update(data: lastChunk)
            }
        }
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Compute full SHA256 hash (for verification)
    static func fullHash(for url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
