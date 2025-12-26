# QuickCleaner

<p align="center">
  <img src="QuickCleaner/Assets.xcassets/AppIcon.appiconset/icon_256.png" alt="QuickCleaner Icon" width="128">
</p>

<p align="center">
  <strong>A powerful macOS disk cleaning utility built with Swift & SwiftUI</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#building">Building</a> •
  <a href="#usage">Usage</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---
<img width="1012" height="764" alt="image" src="https://github.com/user-attachments/assets/f091fbcf-374d-4b7a-983c-95388643642e" />

## Features

- 🧹 **Cache Cleaning** - Remove system and application caches
- 🛠️ **Developer Tools** - Clean Xcode, CocoaPods, Carthage, npm, and other dev caches
- 📁 **Leftover Files** - Find and remove orphaned application files
- 📊 **Large Files** - Discover files taking up the most space
- 🔍 **Duplicate Finder** - Identify and remove duplicate files
- 💻 **System Info** - View detailed system information

## Requirements

- **macOS 14.0+** (Sonoma or later)
- **Swift 5.9+**

## Installation

### Download DMG

1. Download the latest `QuickCleaner-x.x.x.dmg` from [Releases](../../releases)
2. Open the DMG file
3. Drag `QuickCleaner.app` to your Applications folder
4. **First launch**: Right-click the app → Click "Open" → Click "Open" in the dialog

> ⚠️ **Note**: This app is not code-signed. macOS will show a security warning on first launch. The right-click method bypasses Gatekeeper for the initial run.

### Build from Source

See [Building](#building) section below.

## Building

### Prerequisites

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Optional: Install create-dmg for prettier DMGs
brew install create-dmg
```

### Build & Run

```bash
# Clone the repository
git clone https://github.com/yourusername/QuickCleaner.git
cd QuickCleaner

# Build and run in debug mode
swift run

# Build release version
swift build -c release
```

### Create DMG Installer

```bash
# Build DMG with version number
./scripts/build-dmg.sh 1.0.0
```

Output will be in the `dist/` folder:

- `dist/QuickCleaner.app` - Application bundle
- `dist/QuickCleaner-1.0.0.dmg` - Distributable DMG

## Usage

1. **Launch** QuickCleaner from Applications
2. **Select** a cleaning category from the sidebar
3. **Scan** to find files
4. **Review** the results and select items to clean
5. **Clean** to remove selected files

### Categories

| Category        | Description                    |
| --------------- | ------------------------------ |
| Cache Cleaner   | System and app caches          |
| Developer Tools | Xcode, npm, pip, Docker caches |
| Leftover Files  | Orphaned app support files     |
| Large Files     | Files sorted by size           |
| Duplicates      | Hash-based duplicate detection |
| System Info     | Hardware and software details  |

## Project Structure

```
QuickCleaner/
├── QuickCleaner/
│   ├── Models/          # Data models
│   ├── Views/           # SwiftUI views
│   ├── ViewModels/      # View models
│   ├── Services/        # Scanning & file operations
│   ├── Utilities/       # Helper functions
│   └── Assets.xcassets/ # App icons and colors
├── scripts/
│   └── build-dmg.sh     # DMG build script
└── Package.swift        # Swift Package Manager config
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ using Swift & SwiftUI
</p>
