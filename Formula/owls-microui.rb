class OwlsMicroui < Formula
  desc "MicroUI module management CLI — scaffold and remove modules"
  homepage "https://github.com/debuging-life/homebrew-owls-cli"
  version "2.2.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://api.github.com/repos/debuging-life/homebrew-owls-cli/releases/assets/394988730",
          headers: ["Authorization: Bearer #{ENV.fetch("HOMEBREW_GITHUB_API_TOKEN", "")}",
                    "Accept: application/octet-stream"]
      sha256 "9e02025f98b31ce15fb7cfc5e3686b1d383cae46f32fed5e5595bd9cd16ca01c"
    elsif Hardware::CPU.intel?
      url "https://api.github.com/repos/debuging-life/homebrew-owls-cli/releases/assets/394988729",
          headers: ["Authorization: Bearer #{ENV.fetch("HOMEBREW_GITHUB_API_TOKEN", "")}",
                    "Accept: application/octet-stream"]
      sha256 "370d596a1d68a7facd731e1d738d6bd38b90c3048f19a283ce26dd50303d82b4"
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
