class Writer < Formula
  desc "CLI post creation tool for static site generator blogs"
  homepage "https://github.com/brennanbrown/writer-cli"
  url "https://github.com/brennanbrown/writer-cli/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "ae6ed4133f640fa5b7b24644b984b21cb3575fc6b3351a0677465edb93915251"
  license "AGPL-3.0-only"

  depends_on "bash"
  depends_on "git"

  def install
    # Install everything into libexec so writer.sh can find lib/ next to itself
    libexec.install "writer.sh", "lib"
    bin.install_symlink libexec/"writer.sh" => "writer"
  end

  def caveats
    <<~EOS
      Run the setup wizard before first use:
        writer --setup
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/writer --help")
  end
end
