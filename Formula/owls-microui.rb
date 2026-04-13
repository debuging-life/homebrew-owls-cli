class OwlsMicroui < Formula
  desc "MicroUI module management CLI — scaffold and remove modules"
  homepage "https://github.com/debuging-life/homebrew-owls-cli"
  version "2.2.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/debuging-life/homebrew-owls-cli/releases/download/v2.2.0/owls-microui-darwin-arm64",
          headers: ["Authorization: token #{ENV.fetch("HOMEBREW_GITHUB_API_TOKEN", "")}",
                    "Accept: application/octet-stream"]
      sha256 "9e02025f98b31ce15fb7cfc5e3686b1d383cae46f32fed5e5595bd9cd16ca01c"
    elsif Hardware::CPU.intel?
      url "https://github.com/debuging-life/homebrew-owls-cli/releases/download/v2.2.0/owls-microui-darwin-x86_64",
          headers: ["Authorization: token #{ENV.fetch("HOMEBREW_GITHUB_API_TOKEN", "")}",
                    "Accept: application/octet-stream"]
      sha256 "370d596a1d68a7facd731e1d738d6bd38b90c3048f19a283ce26dd50303d82b4"
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
