class Writer < Formula
  desc "CLI post creation tool for static site generator blogs"
  homepage "https://github.com/brennanbrown/writer-cli"
  url "https://github.com/brennanbrown/writer-cli/archive/refs/tags/v1.1.1.tar.gz"
  sha256 "b758352dbd37811c6ef6b80689dab3b81f4ee4dc082bde8294541310e6e24bdf"
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
