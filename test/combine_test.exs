defmodule CombineTest do
  use ExUnit.Case
  
  alias Support.Combine, as: S

#0....+....1....+....2....+
  @long_example """
  do dox alpha alphado end
  """
  test "one long example" do
    assert S.scan_document(@long_example, debug: true) == [{:kwd, "do", 1, 1}, {:ws, " ", 1, 3}, {:text, "dox", 1, 4}, {:ws, " ", 1, 7},
      {:text, "alpha", 1, 8}, {:ws, " ", 1, 13}, {:text, "alphado", 1, 14}, {:ws, " ", 1, 21}, {:kwd, "end", 1, 22}]
  end
end
