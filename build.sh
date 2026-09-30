#!/bin/bash
#
# build.sh — Kompiliert Lumen (Intel x86_64) und baut das .app-Bundle.
#
# Nutzung:  cd Lumen && bash build.sh
#

set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/Sources/Lumen"
BUILD="$ROOT/.build-x86"
APP_DIR="$ROOT/app/Lumen.app"

SDK=$(xcrun --sdk macosx --show-sdk-path)
SWIFT="swiftc"
ARCH="x86_64"
FRAMEWORKS="-framework AppKit -framework Metal -framework QuartzCore -framework CoreVideo -framework ApplicationServices -framework Foundation"

echo "=== Lumen Build (Intel x86_64) ==="
echo "SDK: $SDK"
echo ""

# Alle Swift-Quelltexte sammeln.
SOURCES=$(find "$SRC" -name '*.swift' | sort)

echo "Quelltexte:"
echo "$SOURCES" | sed 's/^/  /'
echo ""

mkdir -p "$BUILD"

# Kompilieren.
echo "Kompiliere..."
$SWIFT \
    -target "$ARCH-apple-macos12.0" \
    -sdk "$SDK" \
    -parse-as-library \
    -O \
    $FRAMEWORKS \
    -o "$BUILD/Lumen" \
    $SOURCES

echo "✅ Kompiliert: $BUILD/Lumen"

# .app-Bundle bauen.
echo ""
echo "Baue .app-Bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources/Shaders"
mkdir -p "$APP_DIR/Contents/Resources/Choreographies"

# Binary
cp "$BUILD/Lumen" "$APP_DIR/Contents/MacOS/Lumen"

# Info.plist
cp "$ROOT/app/Info.plist" "$APP_DIR/Contents/Info.plist"

# App-Icon
cp "$ROOT/app/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

# Shader-Ressourcen
cp "$SRC/Resources/Shaders/"*.metal "$APP_DIR/Contents/Resources/Shaders/"
cp "$SRC/Resources/Choreographies/"*.json "$APP_DIR/Contents/Resources/Choreographies/"

# Quarantine-Flag entfernen (damit Gatekeeper nicht blockt).
xattr -d com.apple.quarantine "$APP_DIR" 2>/dev/null || true

echo ""
echo "✅ App gebaut: $APP_DIR"
echo ""
echo "Starten mit:"
echo "  open \"$APP_DIR\""
echo ""
echo "Hinweis: Für Mosaic (Fenster-Choreografie) benötigt Lumen"
echo "  Bedienhilfen-Berechtigung: Systemeinstellungen → Datenschutz → Bedienhilfen"
