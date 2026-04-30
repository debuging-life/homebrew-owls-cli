class OwlsMicroui < Formula
  desc "MicroUI module management CLI — scaffold and remove modules"
  homepage "https://github.com/debuging-life/homebrew-owls-cli"
  version "2.9.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/debuging-life/homebrew-owls-cli/releases/download/v2.9.0/owls-microui-darwin-arm64"
      sha256 "ddaa4e79fd0dfcba463d0bd07a7a7a6779831c3d66a7adbf751ca48d4b802cf5"
    elsif Hardware::CPU.intel?
      url "https://github.com/debuging-life/homebrew-owls-cli/releases/download/v2.9.0/owls-microui-darwin-x86_64"
      sha256 "3a54324e83999bdd4e684d71399e2bc2b206d3ef5dc4ace3ba0119525b382f64"
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
