# ClippyGo

Menu bar clipboard history for macOS.

Stores text, images, PDFs, and file copies locally (SQLite + on-disk payloads). No network, no accounts, no analytics.

**Requirements:** macOS 14+, Xcode 16+

## Install (Homebrew)

This repo is the tap (same pattern as ModeBar). After a [GitHub Release](https://github.com/safakkizkin/clippygo/releases) exists and `Casks/clippygo.rb` has a real `sha256`:

```bash
brew tap safakkizkin/clippygo https://github.com/safakkizkin/clippygo
brew install --cask clippygo
```

From a local clone:

```bash
brew install --cask ./Casks/clippygo.rb
```

## Releases

Merges to `main` publish a SemVer GitHub Release automatically after CI passes:

| Squash commit / PR title | Bump |
| --- | --- |
| `feat:` … | minor |
| `fix:` / `perf:` … | patch |
| `BREAKING CHANGE:` / `#major` | major |
| anything else | patch (default) |

The workflow builds `ClippyGo-x.y.z.zip`, uploads it, and updates `Casks/clippygo.rb` (`version` + `sha256`) plus `MARKETING_VERSION` in the Xcode project.

Manual bump: Actions → **Release** → Run workflow → choose `patch` / `minor` / `major`.

> The release job pushes the cask/`MARKETING_VERSION` bump to `main`. Under branch protection, allow **GitHub Actions** to bypass required PRs (or add a `RELEASE_GITHUB_TOKEN` PAT secret).

## Build from source

```bash
git clone https://github.com/safakkizkin/clippygo.git
cd clippygo
xcodebuild -scheme ClippyGo -configuration Release -derivedDataPath build
open build/Build/Products/Release/ClippyGo.app
```

Or open `ClippyGo.xcodeproj` in Xcode, set your **Team** under Signing, then Run.

Optional local signing config:

```bash
cp Config/Signing.xcconfig.example Config/Signing.xcconfig
# edit DEVELOPMENT_TEAM, then point the project at that xcconfig if you prefer
```

## Features

- Clipboard history for text, images, PDFs, Finder files
- Disk-backed payloads + size / count limits
- Launch at login
- Multi-language UI (system + many locales, including RTL)
- Menu bar only (`LSUIElement`)

## Privacy

Clipboard history stays on this Mac. Nothing is uploaded.

Contact: [me@safak.dev](mailto:me@safak.dev)

## License

[MIT](LICENSE) © safak.dev
