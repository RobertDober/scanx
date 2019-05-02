defmodule Scanner1Test do
  use ExUnit.Case
  alias Support.Scanner1, as: S

  test "one" do
    assert S.scan_document(" ") == [{:ws, " ", 1, 1}]
  end
end
