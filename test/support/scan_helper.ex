defmodule Support.ScanHelper do
  
  @doc """
       complete_tokens(h1: "# ", ws: " ", text: "hello")

  returns the following

       [{:h1, "# ", 1, 1}, {:ws, " ", 1, 3}, {:text, "hello", 1, 4}]
  """
  def complete_tokens(tokens) do
    with {result, _} <-
      tokens
      |> Enum.map_reduce(1, fn {s, c}, p -> {{s, c, 1, p}, String.length(c) + p} end),
    do: result
  end
end
