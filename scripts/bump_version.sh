#!/usr/bin/env bash
# Update marketing version in the Xcode project and Homebrew cask.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?usage: bump_version.sh <semver> [sha256]}"
SHA256="${2:-}"

PBX="${ROOT}/ClippyGo.xcodeproj/project.pbxproj"
CASK="${ROOT}/homebrew/Casks/clippygo.rb"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must be semver X.Y.Z (got: $VERSION)" >&2
  exit 1
fi

# Bump CURRENT_PROJECT_VERSION (integer build number) by 1.
CURRENT="$(
  awk -F' = ' '/CURRENT_PROJECT_VERSION = / { gsub(/;/, "", $2); print $2; exit }' "$PBX"
)"
if [[ -z "$CURRENT" ]]; then
  echo "error: CURRENT_PROJECT_VERSION not found in $PBX" >&2
  exit 1
fi
NEXT_BUILD=$((CURRENT + 1))

perl -pi -e "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = ${VERSION};/g" "$PBX"
perl -pi -e "s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = ${NEXT_BUILD};/g" "$PBX"

if [[ -n "$SHA256" ]]; then
  perl -pi -e "s/^  version \".*\"/  version \"${VERSION}\"/" "$CASK"
  perl -pi -e "s/^  sha256 .*/  sha256 \"${SHA256}\"/" "$CASK"
else
  perl -pi -e "s/^  version \".*\"/  version \"${VERSION}\"/" "$CASK"
fi

echo "bumped marketing=${VERSION} build=${NEXT_BUILD}"
