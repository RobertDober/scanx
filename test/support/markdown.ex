defmodule Support.Markdown do
  use ScanX

  # 
  # Local Defitions
  # ---------------
  ws = [" ", "\t"]
  headers = ["###### ", "##### ", "#### ", "### ", "## ", "# "]
  bquotes = ~w{`````` ````` ```` ``` `` `}


  #
  # State Definitions
  # -----------------
  # ... :start at the beginning
  state :start do
    empty :halt, emit: :blank
    on ws, :indent
    for {header, level} <- Enum.zip(headers, Stream.iterate(6, &(&1-1))) do
      on header, :new, emit: "h#{level}", collect: :before
    end
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, "bq#{size}"
    end
    anything :text
  end

  # ... all other states in alphabetical order
  state :indent do
    empty :halt, emit: :blank
    on ws, :indent
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, "bq#{size}", emit: :indent
    end
    anything :text, emit: :indent
  end

  state :new do
    empty :halt
    on ws, :ws
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, "bq#{size}"
    end
    anything :text
  end

  state :text do
    empty :halt, emit: :text
    on ws, :ws, emit: :text
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, "bq#{size}", emit: :text
    end
    anything :text
  end

  state :ws do
    empty :halt, emit: :trailing_ws
    on ws, :ws
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote "bq#{size}"
    end
    anything :text, emit: :ws
  end
end
