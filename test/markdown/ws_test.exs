defmodule Markdown.WsTest do
  use Support.MarkdownTestHelper
  
  describe "indent lines" do
    [" ", "    ", "                    "]
    |> Enum.each( fn indent -> 
      test "indent for #{String.length(indent)} spaces" do
        assert scan(unquote(indent)) == complete_tokens( indent: unquote(indent) )
      end
    end)
  end

  describe "empty lines" do
    test "empty" do
      assert scan("") == []
    end
  end
end
