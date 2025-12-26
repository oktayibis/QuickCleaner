import XCTest
@testable import QuickCleaner

final class ByteFormatterTests: XCTestCase {
    
    func testFormatBytes() {
        XCTAssertEqual(ByteFormatter.format(0), "0 B")
        XCTAssertEqual(ByteFormatter.format(100), "100 B")
        XCTAssertEqual(ByteFormatter.format(1024), "1.00 KB")
        XCTAssertEqual(ByteFormatter.format(1024 * 1024), "1.00 MB")
        XCTAssertEqual(ByteFormatter.format(1024 * 1024 * 1024), "1.00 GB")
        XCTAssertEqual(ByteFormatter.format(1024 * 1024 * 1024 * 1024), "1.00 TB")
    }
    
    func testFormatCompact() {
        XCTAssertEqual(ByteFormatter.formatCompact(1024 * 1024 * 500), "500.00MB")
        XCTAssertEqual(ByteFormatter.formatCompact(1024 * 1024 * 1024 * 2), "2.00GB")
    }
}

final class FileCategoryTests: XCTestCase {
    
    func testVideoCategory() {
        XCTAssertEqual(FileCategory.category(for: "mp4"), .video)
        XCTAssertEqual(FileCategory.category(for: "MOV"), .video)
        XCTAssertEqual(FileCategory.category(for: "mkv"), .video)
    }
    
    func testImageCategory() {
        XCTAssertEqual(FileCategory.category(for: "jpg"), .image)
        XCTAssertEqual(FileCategory.category(for: "PNG"), .image)
        XCTAssertEqual(FileCategory.category(for: "heic"), .image)
    }
    
    func testAudioCategory() {
        XCTAssertEqual(FileCategory.category(for: "mp3"), .audio)
        XCTAssertEqual(FileCategory.category(for: "WAV"), .audio)
    }
    
    func testArchiveCategory() {
        XCTAssertEqual(FileCategory.category(for: "zip"), .archive)
        XCTAssertEqual(FileCategory.category(for: "tar"), .archive)
    }
    
    func testDiskImageCategory() {
        XCTAssertEqual(FileCategory.category(for: "dmg"), .diskImage)
        XCTAssertEqual(FileCategory.category(for: "iso"), .diskImage)
    }
    
    func testOtherCategory() {
        XCTAssertEqual(FileCategory.category(for: "xyz"), .other)
        XCTAssertEqual(FileCategory.category(for: "unknown"), .other)
    }
}

final class SystemInfoTests: XCTestCase {
    
    func testCurrentSystemInfo() {
        let info = SystemInfo.current()
        
        XCTAssertFalse(info.homeDirectory.isEmpty)
        XCTAssertFalse(info.username.isEmpty)
        XCTAssertFalse(info.hostname.isEmpty)
        XCTAssertTrue(info.diskUsage.totalBytes > 0)
        XCTAssertTrue(info.diskUsage.freeBytes > 0)
    }
}

final class DuplicateGroupTests: XCTestCase {
    
    func testTotalWasted() {
        let files = [
            DuplicateFile(path: "/path/1", name: "file1"),
            DuplicateFile(path: "/path/2", name: "file2"),
            DuplicateFile(path: "/path/3", name: "file3"),
        ]
        
        let group = DuplicateGroup(hash: "abc123", files: files, fileSize: 1024 * 1024)
        
        // 3 files, 1MB each, 2 are duplicates = 2MB wasted
        XCTAssertEqual(group.totalWasted, 2 * 1024 * 1024)
        XCTAssertEqual(group.duplicateCount, 2)
    }
    
    func testSingleFileNoWaste() {
        let files = [
            DuplicateFile(path: "/path/1", name: "file1"),
        ]
        
        let group = DuplicateGroup(hash: "abc123", files: files, fileSize: 1024 * 1024)
        
        XCTAssertEqual(group.totalWasted, 0)
        XCTAssertEqual(group.duplicateCount, 0)
    }
}
