#!/usr/bin/env bash
# Build a zip for GitHub Releases / Homebrew cask.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(
    awk -F' = ' '/MARKETING_VERSION = / { gsub(/;/, "", $2); print $2; exit }' \
      ClippyGo.xcodeproj/project.pbxproj
  )"
fi
if [[ -z "$VERSION" ]]; then
  echo "error: could not determine version" >&2
  exit 1
fi

DERIVED="${ROOT}/build"
APP="${DERIVED}/Build/Products/Release/ClippyGo.app"
OUT_DIR="${ROOT}/dist"
ZIP="${OUT_DIR}/ClippyGo-${VERSION}.zip"
SHA_FILE="${OUT_DIR}/ClippyGo-${VERSION}.sha256"

echo "==> Building Release ${VERSION}"
rm -rf "$DERIVED" "$OUT_DIR"
mkdir -p "$OUT_DIR"

xcodebuild \
  -project ClippyGo.xcodeproj \
  -scheme ClippyGo \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED" \
  ONLY_ACTIVE_ARCH=YES \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  MARKETING_VERSION="$VERSION" \
  build

if [[ ! -d "$APP" ]]; then
  echo "error: missing app at $APP" >&2
  exit 1
fi

echo "==> Zipping"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "==> SHA-256"
shasum -a 256 "$ZIP" | tee "$SHA_FILE"
echo
echo "ZIP=$ZIP"
echo "SHA_FILE=$SHA_FILE"
