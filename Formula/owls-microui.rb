class OwlsMicroui < Formula
  desc "MicroUI module management CLI — scaffold and remove modules"
  homepage "https://github.com/debuging-life/homebrew-owls-cli"
  version "2.3.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/debuging-life/homebrew-owls-cli/releases/download/v2.3.0/owls-microui-darwin-arm64"
      sha256 "77049de14ca7f0df60cdd53b747078d21e0031886bd4f44efd874ae4c149e2a8"
    elsif Hardware::CPU.intel?
      url "https://github.com/debuging-life/homebrew-owls-cli/releases/download/v2.3.0/owls-microui-darwin-x86_64"
      sha256 "d7405a81dcb67c6f99a3e706c66fbf7270777bc2cd8b123910e0c5b521b96af3"
    end
  end

  def install
    bin.install "owls-microui-darwin-arm64" => "owls-microui" if Hardware::CPU.arm?
    bin.install "owls-microui-darwin-x86_64" => "owls-microui" if Hardware::CPU.intel?
  end

  test do
    assert_match "MicroUI module management CLI", shell_output("#{bin}/owls-microui --help")
  end
end
