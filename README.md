# ClippyGo

Menu bar clipboard history for macOS.

Stores text, images, PDFs, and file copies locally (SQLite + on-disk payloads). No network, no accounts, no analytics.

**Requirements:** macOS 14+, Xcode 16+

## Install (Homebrew cask)

After the first GitHub Release exists:

```bash
brew tap safakkizkin/tap
brew install --cask clippygo
```

Or install a release artifact directly:

```bash
brew install --cask ./homebrew/Casks/clippygo.rb
```

> The tap formula points at GitHub Releases. Until a release `.zip`/`.dmg` is published, use **Build from source** below.

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
