defmodule Markdown.WsTest do
  use Support.MarkdownTest
  
  describe "blank lines" do
    ["", " ", "    ", "                    "]
    |> Enum.each( fn blank -> 
      test "blank for #{String.length(blank)} spaces" do
        assert scan(unquote(blank)) == complete_tokens( blank: unquote(blank) )
      end
    end)
  end
end
