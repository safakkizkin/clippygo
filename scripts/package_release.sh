#!/usr/bin/env bash
# Build a notarization-ready zip for GitHub Releases / Homebrew cask.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-1.0.0}"
DERIVED="${ROOT}/build"
APP="${DERIVED}/Build/Products/Release/ClippyGo.app"
OUT_DIR="${ROOT}/dist"
ZIP="${OUT_DIR}/ClippyGo-${VERSION}.zip"

echo "==> Building Release"
rm -rf "$DERIVED" "$OUT_DIR"
mkdir -p "$OUT_DIR"

xcodebuild \
  -scheme ClippyGo \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  build

if [[ ! -d "$APP" ]]; then
  echo "error: missing app at $APP" >&2
  exit 1
fi

echo "==> Zipping"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "==> SHA-256"
shasum -a 256 "$ZIP"
echo
echo "Upload $ZIP to GitHub Releases as v${VERSION}, then put the sha256 into homebrew/Casks/clippygo.rb"
