defmodule Support.Markdown do
  use ScanX

  ws = [" ", "\t"]
  headers = ["###### ", "##### ", "#### ", "### ", "## ", "# "]
  bquotes = ~w{`````` ````` ```` ``` `` `}

  state :start do
    empty :halt
    on ws, :ws
    for {header, level} <- Enum.zip(headers, Stream.iterate(6, &(&1-1))) do
      on header, :new, emit:  "h#{level}"
    end
  end

  state :new do
  end
end
