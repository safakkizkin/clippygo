cask "clippygo" do
  version "1.0.0"
  sha256 :no_check # replace with `shasum -a 256` of the release zip after first publish

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
end
