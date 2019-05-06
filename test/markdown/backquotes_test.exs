defmodule Markdown.BackquotesTest do
  use Support.MarkdownTest

  describe "all backquotes in isolation" do
    ~w{` `` ``` ````` ```` ``````}
    |> Enum.each(fn bquotes ->
      test "isolated #{bquotes}" do
        len = String.length(unquote(bquotes))
        sym = String.to_atom("bq#{len}")
        assert scan(unquote(bquotes)) == complete_tokens([{sym, unquote(bquotes)}])
      end
    end)
  end

  describe "too long" do
    test "to be a backquote" do
      line = "```````"
      assert scan(line) == complete_tokens(text: line)
    end
  end

  describe "backquotes inline" do
    test "single and double" do
      line = "hello` `` world"
      assert scan(line) == complete_tokens(text: "hello", bq1: "`", ws: " ", bq2: "``", ws: " ", text: "world")
    end
  end
  
end
