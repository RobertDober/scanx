defmodule Markdown.BlockquoteTest do
  use Support.MarkdownTest
  
  describe "blockquotes" do
    test "this is a blockquote" do
      line = ">"
      assert scan(line) == complete_tokens(blockquote: ">")
    end
    test "and so is this one" do
      line = "> "
      assert scan(line) == complete_tokens(blockquote: "> ")
    end
    test "but this is not" do
      line = ">>"
      assert scan(line) == complete_tokens(text: ">>")
    end
    test "nor is this one" do
      line = " > > x"
      assert scan(line) == complete_tokens(indent: " ", text: ">", ws: " ", text: ">", ws: " ", text: "x")
    end
  end

  describe "blockquote follow up" do
    test "this is still a header" do
      line = "> # headline"
      assert scan(line) == complete_tokens(blockquote: "> ", h1: "# ", text: "headline")
    end
    test "but this is not a header" do
      line = "># headline"
      assert scan(line) == complete_tokens(text: ">#", ws: " ", text: "headline")
    end
    test "this is still a list item" do
      line = "> * one"
      assert scan(line) == complete_tokens(blockquote: "> ", ul: "* ", text: "one")
    end
  end
end
