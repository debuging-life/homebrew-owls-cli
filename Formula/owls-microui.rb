class OwlsMicroui < Formula
  desc "MicroUI module management CLI — scaffold and remove modules"
  homepage "https://github.com/debuging-life/homebrew-owls-cli"
  version "2.8.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/debuging-life/homebrew-owls-cli/releases/download/v2.8.0/owls-microui-darwin-arm64"
      sha256 "051de89c95c1a8dd7aaeeba1f15d2bd5e223f2c69e3187910bb5a89c580734fa"
    elsif Hardware::CPU.intel?
      url "https://github.com/debuging-life/homebrew-owls-cli/releases/download/v2.8.0/owls-microui-darwin-x86_64"
      sha256 "0f905ea760401e2bfdbec301627876d6727dc18ba7f80f86d0fecff07ec48bfe"
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
