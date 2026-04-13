class OwlsMicroui < Formula
  desc "MicroUI module management CLI — scaffold and remove modules"
  homepage "https://github.com/debuging-life/owls-cli"
  version "2.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/debuging-life/owls-cli/releases/download/v2.1.0/owls-microui-darwin-arm64"
      sha256 "REPLACE_WITH_ARM64_SHA256"
    elsif Hardware::CPU.intel?
      url "https://github.com/debuging-life/owls-cli/releases/download/v2.1.0/owls-microui-darwin-x86_64"
      sha256 "REPLACE_WITH_X86_64_SHA256"
    end
  end

  def install
    binary_name = stable.url.split("/").last
    bin.install binary_name => "owls-microui"
  end

  test do
    assert_match "MicroUI module management CLI", shell_output("#{bin}/owls-microui --help")
  end
end
