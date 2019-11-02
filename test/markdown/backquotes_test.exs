defmodule Markdown.BackquotesTest do
  use Support.MarkdownTestHelper

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
    test "longer" do
      line = "``` ````a````` `````` ```````"
      assert scan(line) == complete_tokens(bq3: "```", ws: " ", bq4: "````", text: "a", bq5: "`````", ws: " ", bq6: "``````", ws: " ", text: "```````")
    end
    test "miscelaneous" do
      line = "# ``````` a`b"
      assert scan(line) == complete_tokens(h1: "# ", text: "```````", ws: " ", text: "a", bq1: "`", text: "b")
    end
  end
  
end
