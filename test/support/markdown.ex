defmodule Support.Markdown do
  use ScanX

  # 
  # Local Defitions
  # ---------------
  ws = [" ", "\t"]
  headers = ["###### ", "##### ", "#### ", "### ", "## ", "# "]
  bquotes = ~w{`````` ````` ```` ``` `` `}
  bq7 = "```````"


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
    on bq7, :text
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, :new, emit: "bq#{size}", collect: :before
    end
    anything :text
  end

  # ... all other states in alphabetical order
  state :indent do
    empty :halt, emit: :blank
    on ws, :indent
    anything :text, emit: :indent
  end

  state :new do
    empty :halt
    on ws, :ws
    on bq7, :text
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, :new, emit: "bq#{size}", collect: :before
    end
    anything :text
  end

  state :text do
    empty :halt, emit: :text
    on ws, :ws, emit: :text
    on bq7, :text
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, :new, emit: "bq#{size}", collect: :before
    end
    anything :text
  end

  state :ws do
    empty :halt, emit: :trailing_ws
    on ws, :ws
    on bq7, :text
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, :new, emit: "bq#{size}", collect: :before
    end
    anything :text, emit: :ws
  end
end
