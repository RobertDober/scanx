defmodule Markdown.ListTest do
  use Support.MarkdownTest

  describe "uls" do
    test "*" do
      line = "* "
      assert scan(line) == complete_tokens(ul: "* ")
    end
    test "-" do
      line = "- "
      assert scan(line) == complete_tokens(ul: "- ")
    end
  end

  describe "ols" do
    test "1." do
      line = "1. "
      assert scanx(line) == complete_tokens(ol: "1. ")
    end

    test "42395." do
      line = "42395. "
      assert scan(line) == complete_tokens(ol: "42395. ")
    end
  end

  describe "uls and follow up" do
    test "ul + headers" do
    end
    test "ul + ul" do
    end
  end
  
end
