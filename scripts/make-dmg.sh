#!/usr/bin/env bash
# scripts/make-dmg.sh
# Phase 5: Builds a Release .dmg for PruneIt and writes a SHA-256 checksum.
# Usage: bash scripts/make-dmg.sh
# Output: build/PruneIt-<version>.dmg and build/PruneIt-<version>.dmg.sha256
#
# Prerequisites:
#   - Xcode command-line tools installed (xcodebuild, hdiutil, plutil)
#   - No Developer ID certificate required (ad-hoc / unsigned)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
APP_NAME="PruneIt"
SCHEME="PruneIt"
PROJECT="$REPO_ROOT/PruneIt.xcodeproj"
CONFIGURATION="Release"

echo "==> Cleaning build dir..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$DERIVED_DATA"

echo "==> Building $APP_NAME ($CONFIGURATION)..."
xcodebuild clean build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR/app"

APP_PATH="$BUILD_DIR/app/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: $APP_PATH not found after build. Check scheme/target names." >&2
  exit 1
fi

# Read version from built bundle
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "0.0.0")
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

echo "==> Creating .dmg ($DMG_NAME)..."
# Create a temporary folder with the app and an Applications symlink
STAGING_DIR="$BUILD_DIR/dmg-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "==> Computing SHA-256..."
SHA=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
echo "$SHA  $DMG_NAME" > "$DMG_PATH.sha256"

echo ""
echo "==> Done."
echo "    DMG:    $DMG_PATH"
echo "    SHA256: $DMG_PATH.sha256"
echo "    SHA256 value: $SHA"
