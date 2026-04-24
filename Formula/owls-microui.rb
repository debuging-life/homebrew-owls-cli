class OwlsMicroui < Formula
  desc "MicroUI module management CLI — scaffold and remove modules"
  homepage "https://github.com/debuging-life/homebrew-owls-cli"
  version "2.5.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/debuging-life/homebrew-owls-cli/releases/download/v2.5.0/owls-microui-darwin-arm64"
      sha256 "205ae2ecdd805447d48911383ee977bfbeea2fa655ad7cf4356491486b3678a2"
    elsif Hardware::CPU.intel?
      url "https://github.com/debuging-life/homebrew-owls-cli/releases/download/v2.5.0/owls-microui-darwin-x86_64"
      sha256 "fe1a022c6a8d977caa72ab9cfef4bef921e1959d4b3ab9f840681c9b350cb3f5"
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
