#!/usr/bin/env bash
# Compute the next SemVer tag from git history (no Docker / Linux-only actions).
# Usage: next_semver.sh [default_bump]
#   default_bump: patch|minor|major  (used when commits don't imply a higher bump)
# Env:
#   FORCE_BUMP=patch|minor|major  — ignore commit scan, always use this bump
# Outputs to GITHUB_OUTPUT when set:
#   new_tag, version, part
set -euo pipefail

DEFAULT_BUMP="${1:-patch}"
FORCE_BUMP="${FORCE_BUMP:-}"

if [[ ! "$DEFAULT_BUMP" =~ ^(patch|minor|major)$ ]]; then
  echo "error: bump must be patch|minor|major (got: $DEFAULT_BUMP)" >&2
  exit 1
fi

latest="$(git describe --tags --abbrev=0 2>/dev/null || true)"
if [[ -z "$latest" ]]; then
  base="0.0.0"
  range=""
else
  base="${latest#v}"
  range="${latest}..HEAD"
fi

if [[ ! "$base" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "error: latest tag is not semver: ${latest:-<none>}" >&2
  exit 1
fi
major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

bump="$DEFAULT_BUMP"
if [[ -n "$FORCE_BUMP" ]]; then
  if [[ ! "$FORCE_BUMP" =~ ^(patch|minor|major)$ ]]; then
    echo "error: FORCE_BUMP must be patch|minor|major" >&2
    exit 1
  fi
  bump="$FORCE_BUMP"
elif [[ -n "$range" ]]; then
  log="$(git log "$range" --pretty=%B)"
  # Prefer the highest applicable bump from conventional commits.
  if printf '%s\n' "$log" | grep -Eiq '(^|[[:space:]])BREAKING CHANGE:|[[:space:]]#major\b|^[a-z]+(\([^)]+\))?!:'; then
    bump="major"
  elif printf '%s\n' "$log" | grep -Eiq '^feat(\([^)]+\))?:'; then
    bump="minor"
  elif printf '%s\n' "$log" | grep -Eiq '^(fix|perf)(\([^)]+\))?:'; then
    bump="patch"
  fi
fi

case "$bump" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
esac

version="${major}.${minor}.${patch}"
tag="v${version}"

# No commits since last tag and not forced → nothing to publish.
if [[ -z "$FORCE_BUMP" && -n "$latest" ]]; then
  ahead="$(git rev-list "${latest}..HEAD" --count)"
  if [[ "$ahead" -eq 0 ]]; then
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
      {
        echo "new_tag="
        echo "version="
        echo "part="
      } >> "$GITHUB_OUTPUT"
    fi
    echo "no commits since ${latest}; skip"
    exit 0
  fi
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "new_tag=${tag}"
    echo "version=${version}"
    echo "part=${bump}"
  } >> "$GITHUB_OUTPUT"
fi

echo "latest=${latest:-none} bump=${bump} -> ${tag}"
