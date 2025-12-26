# QuickCleaner Build Scripts

## Prerequisites

- **macOS 14.0+** (Sonoma or later)
- **Xcode Command Line Tools**: `xcode-select --install`
- **Swift 5.9+**: Included with Xcode

### Optional (for prettier DMGs)

```bash
brew install create-dmg
```

## Building the DMG

### Quick Build

```bash
./scripts/build-dmg.sh
```

### With Version Number

```bash
./scripts/build-dmg.sh 1.2.0
```

### Output

After running, you'll find:

- **App Bundle**: `dist/QuickCleaner.app`
- **DMG Installer**: `dist/QuickCleaner-{version}.dmg`

## Installation Instructions for Users

Since this app is **not code-signed** (no Apple Developer account), users will see a Gatekeeper warning.

### To install:

1. Download `QuickCleaner-x.x.x.dmg`
2. Double-click to open the DMG
3. Drag `QuickCleaner.app` to the Applications folder
4. **First launch**: Right-click on the app → click "Open" → click "Open" again in the dialog

> **Note**: The right-click method is only needed for the first launch. After that, the app opens normally.

## Troubleshooting

### "App is damaged and can't be opened"

Run this command in Terminal:

```bash
xattr -cr /Applications/QuickCleaner.app
```

### Build fails with missing dependencies

```bash
swift package resolve
swift build -c release
```
