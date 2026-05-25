class Writer < Formula
  desc "CLI post creation tool for static site generator blogs"
  homepage "https://github.com/brennanbrown/writer-cli"
  url "https://github.com/brennanbrown/writer-cli/archive/refs/tags/v1.1.2.tar.gz"
  sha256 "845e16dbf3c438196754d9a6956db265e5f371b5eb061531ca9b54670f2a5096"
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
