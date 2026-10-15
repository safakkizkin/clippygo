cask "clippygo" do
  version "1.0.0"
  sha256 "dd2f8f626b7e029b91624735323358011cb508f906452344ec9f536333cecd5e"

  url "https://github.com/safakkizkin/clippygo/releases/download/v#{version}/ClippyGo-#{version}.zip"
  name "ClippyGo"
  desc "Menu bar clipboard history for macOS"
  homepage "https://github.com/safakkizkin/clippygo"

  depends_on macos: ">= :sonoma"

  app "ClippyGo.app"

  zap trash: [
    "~/Library/Application Support/ClippyGo",
    "~/Library/Caches/dev.safak.clippygo",
    "~/Library/Preferences/dev.safak.clippygo.plist",
  ]

  caveats <<~EOS
    ClippyGo releases are ad-hoc signed (not Developer ID / notarized).
    If Gatekeeper blocks launch after install:

      xattr -dr com.apple.quarantine /Applications/ClippyGo.app

    Or right-click the app → Open.
  EOS
end
