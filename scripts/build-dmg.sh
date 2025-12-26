#!/bin/bash

# ============================================================================
# QuickCleaner DMG Build Script
# Creates a distributable DMG file for macOS (without code signing)
# ============================================================================

set -e  # Exit on error

# Configuration
APP_NAME="QuickCleaner"
VERSION="${1:-1.0.0}"
DMG_NAME="${APP_NAME}-${VERSION}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/.build/release"
DIST_DIR="${PROJECT_DIR}/dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
DMG_PATH="${DIST_DIR}/${DMG_NAME}.dmg"
DMG_TEMP="${DIST_DIR}/${DMG_NAME}-temp.dmg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  QuickCleaner DMG Builder v${VERSION}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Clean previous builds
echo -e "${YELLOW}[1/6]${NC} Cleaning previous builds..."
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

# Step 2: Build the application in Release mode
echo -e "${YELLOW}[2/6]${NC} Building ${APP_NAME} in Release mode..."
cd "${PROJECT_DIR}"
swift build -c release

if [ ! -f "${BUILD_DIR}/${APP_NAME}" ]; then
    echo -e "${RED}Error: Build failed - executable not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build successful${NC}"

# Step 3: Create .app bundle structure
echo -e "${YELLOW}[3/6]${NC} Creating .app bundle..."

mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Copy resources if they exist
if [ -d "${BUILD_DIR}/${APP_NAME}_${APP_NAME}.bundle" ]; then
    cp -R "${BUILD_DIR}/${APP_NAME}_${APP_NAME}.bundle/"* "${APP_BUNDLE}/Contents/Resources/" 2>/dev/null || true
fi

# Create Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.quickcleaner.app</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

echo -e "${GREEN}✓ App bundle created${NC}"

# Step 4: Create app icon (.icns)
echo -e "${YELLOW}[4/6]${NC} Processing app icon..."
ICON_SOURCE="${PROJECT_DIR}/QuickCleaner/Assets.xcassets/AppIcon.appiconset"
ICONSET_DIR="${DIST_DIR}/AppIcon.iconset"

if [ -d "${ICON_SOURCE}" ] && [ -f "${ICON_SOURCE}/icon_1024.png" ]; then
    # Create iconset directory structure
    mkdir -p "${ICONSET_DIR}"
    
    # Copy and rename icons to iconset format
    cp "${ICON_SOURCE}/icon_16.png" "${ICONSET_DIR}/icon_16x16.png"
    cp "${ICON_SOURCE}/icon_32.png" "${ICONSET_DIR}/icon_16x16@2x.png"
    cp "${ICON_SOURCE}/icon_32.png" "${ICONSET_DIR}/icon_32x32.png"
    cp "${ICON_SOURCE}/icon_64.png" "${ICONSET_DIR}/icon_32x32@2x.png"
    cp "${ICON_SOURCE}/icon_128.png" "${ICONSET_DIR}/icon_128x128.png"
    cp "${ICON_SOURCE}/icon_256.png" "${ICONSET_DIR}/icon_128x128@2x.png"
    cp "${ICON_SOURCE}/icon_256.png" "${ICONSET_DIR}/icon_256x256.png"
    cp "${ICON_SOURCE}/icon_512.png" "${ICONSET_DIR}/icon_256x256@2x.png"
    cp "${ICON_SOURCE}/icon_512.png" "${ICONSET_DIR}/icon_512x512.png"
    cp "${ICON_SOURCE}/icon_1024.png" "${ICONSET_DIR}/icon_512x512@2x.png"
    
    # Generate .icns file using iconutil
    iconutil -c icns "${ICONSET_DIR}" -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    
    # Also copy 1024 PNG for DMG volume icon
    cp "${ICON_SOURCE}/icon_512.png" "${APP_BUNDLE}/Contents/Resources/AppIcon.png"
    
    # Cleanup iconset
    rm -rf "${ICONSET_DIR}"
    
    echo -e "${GREEN}✓ App icon created (.icns)${NC}"
else
    echo -e "${YELLOW}⚠ No icon found at ${ICON_SOURCE}${NC}"
fi

# Step 5: Create DMG
echo -e "${YELLOW}[5/6]${NC} Creating DMG installer..."

# Check if create-dmg is installed
if command -v create-dmg &> /dev/null; then
    echo "Using create-dmg for beautiful DMG..."
    
    create-dmg \
        --volname "${APP_NAME}" \
        --volicon "${APP_BUNDLE}/Contents/Resources/AppIcon.png" 2>/dev/null || true \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 150 185 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 450 185 \
        --no-internet-enable \
        "${DMG_PATH}" \
        "${APP_BUNDLE}" 2>/dev/null || {
            # Fallback if create-dmg fails
            echo "create-dmg failed, using hdiutil fallback..."
            USE_HDIUTIL=true
        }
else
    USE_HDIUTIL=true
fi

if [ "${USE_HDIUTIL}" = true ]; then
    echo "Using hdiutil for DMG creation..."
    
    # Create a temporary directory for DMG contents
    DMG_STAGING="${DIST_DIR}/dmg-staging"
    mkdir -p "${DMG_STAGING}"
    
    # Copy app to staging
    cp -R "${APP_BUNDLE}" "${DMG_STAGING}/"
    
    # Create Applications symlink
    ln -s /Applications "${DMG_STAGING}/Applications"
    
    # Create the DMG
    hdiutil create -volname "${APP_NAME}" \
        -srcfolder "${DMG_STAGING}" \
        -ov -format UDZO \
        "${DMG_PATH}"
    
    # Cleanup staging
    rm -rf "${DMG_STAGING}"
fi

if [ -f "${DMG_PATH}" ]; then
    echo -e "${GREEN}✓ DMG created successfully${NC}"
else
    echo -e "${RED}Error: DMG creation failed${NC}"
    exit 1
fi

# Step 6: Final summary
echo -e "${YELLOW}[6/6]${NC} Build complete!"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Build Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  App Bundle: ${APP_BUNDLE}"
echo -e "  DMG File:   ${DMG_PATH}"
echo -e "  Size:       $(du -h "${DMG_PATH}" | cut -f1)"
echo ""
echo -e "${YELLOW}⚠ Important Notes:${NC}"
echo -e "  • This app is NOT code-signed (no Apple Developer account)"
echo -e "  • Users will see a Gatekeeper warning when opening"
echo -e "  • Instruct users to right-click → Open to bypass the warning"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
