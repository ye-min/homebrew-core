require "language/node"

class MarkdownlintCli2 < Formula
  desc "Fast, flexible, config-based cli for linting Markdown/CommonMark files"
  homepage "https://github.com/DavidAnson/markdownlint-cli2"
  url "https://registry.npmjs.org/markdownlint-cli2/-/markdownlint-cli2-0.8.0.tgz"
  sha256 "96f52d6fc6ed83b0748467f780dafe973a965398567ebc5a1bb308bc01c8d7aa"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, all: "b5e8f0b890389be908aac53e3b9adb280c847c0590d0d54e17860f8361e24681"
  end

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    (testpath/"test-bad.md").write <<~EOS
      # Header 1
      body
    EOS
    (testpath/"test-good.md").write <<~EOS
      # Header 1

      body
    EOS
    assert_match "Summary: 1 error(s)",
      shell_output("#{bin}/markdownlint-cli2 :#{testpath}/test-bad.md 2>&1", 1)
    assert_match "Summary: 0 error(s)",
      shell_output("#{bin}/markdownlint-cli2 :#{testpath}/test-good.md")
  end
end
