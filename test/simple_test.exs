defmodule SimpleTest do
  use ExUnit.Case
  
  alias Support.Simple, as: S

  test "simple" do
#            0....+....1....+....2....+
    simple = "abc"
    IO.inspect S.common_blocks
    assert S.scan_document(simple, debug: true) == [{:text, "abc", 1, 1}]
  end
end
