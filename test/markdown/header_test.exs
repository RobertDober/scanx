defmodule Markdown.HeaderTest do
  use ExUnit.Case
  alias Support.Markdown, as: S
  import Support.ScanHelper, only: [complete_tokens: 1]

  describe "headers" do
    test "h6" do
      assert S.scan_document("###### ") == [{:h6, "###### ", 1, 1}]
    end
    test "h5" do
      assert S.scan_document("##### ") == [{:h5, "##### ", 1, 1}]
    end
    test "h4" do
      assert S.scan_document("#### ") == [{:h4, "#### ", 1, 1}]
    end
    test "h3" do
      assert S.scan_document("### ") == [{:h3, "### ", 1, 1}]
    end
    test "h2" do
      assert S.scan_document("## ") == [{:h2, "## ", 1, 1}]
    end
    test "h1" do
      assert S.scan_document("# ") == [{:h1, "# ", 1, 1}]
    end
  end

  describe "headers and more" do
    test "h1 and more" do
      line = "#  hello"
      tokens = [ h1: "# ", ws: " ", text: "hello" ]
      assert S.scan_document(line) == complete_tokens(tokens)
    end
  end

  describe "not headers" do
    test "not h3" do
      line = " # hello"
      tokens = [indent: " ", text: "#", ws: " ", text: "hello"]
      assert S.scan_document(line) == complete_tokens(tokens)
    end
  end

end
