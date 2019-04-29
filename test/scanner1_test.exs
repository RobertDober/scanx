defmodule Scanner1Test do
  use ExUnit.Case
  alias Support.Scanner1, as: S
  
  test "one" do
    S.scan_line(" ")
    |> IO.inspect
    
  end
end
