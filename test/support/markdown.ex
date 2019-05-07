defmodule Support.Markdown do
  use ScanX

  # 
  # Local Defitions
  # ---------------
  ws      = [" ", "\t"]
  headers = ["###### ", "##### ", "#### ", "### ", "## ", "# "]
  bquotes = ~w{`````` ````` ```` ``` `` `}
  digits  = "0123456789" |> String.graphemes
  uls     = ["- ", "* "]
  
  define_block :halt_on_empty do
    empty :halt
  end

  #
  # State Definitions
  # -----------------
  # ... :start at the beginning
  state :start do
    include :halt_on_empty
    on ">", :blockquote
    on ws, :indent
    on uls, :ul
    on digits, :digits
    for {header, level} <- Enum.zip(headers, Stream.iterate(6, &(&1-1))) do
      on header, :new, emit: "h#{level}", collect: :before
    end
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, "bq#{size}"
    end
    anything :text
  end

  #
  # ... all other states in alphabetical order
  state :blockquote do
    empty :halt, emit: :blockquote
    on ws, :start, collect: :before, emit: :blockquote 
    on digits, :ol
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, "bq#{size}", emit: :text
    end
    anything :text
  end

  state :bq6 do
    empty :halt, emit: :bq6
    on ws, :ws, emit: :bq6
    on "`", :text
    anything :text, emit: :bq6
  end
  for {bquote, size} <- Enum.map(bquotes, &{&1, String.length(&1)}) do
    bq_state = "bq#{size}"
    state bq_state do
      empty :halt, emit: bq_state
      on ws, :ws, emit: bq_state
      anything :text, emit: bq_state
    end
  end

  state :digits do
    empty :halt, emit: :text
    on uls, :ul
    on digits, :digits
    on ".", :ol
    on ws, :ws, emit: :text
    anything :text
  end

  state :indent do
    empty :halt, emit: :indent
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

  state :ol do
    empty :halt, emit: :text
    on ws, :new, collect: :before, emit: :ol
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

  state :ul do
    empty :halt, emit: :ul
    on ws, :ws, emit: :ul 
    for {header, level} <- Enum.zip(headers, Stream.iterate(6, &(&1-1))) do
      on header, :new, emit: {:ul, "h#{level}"}
    end
    anything :text, emit: :ul
  end

  state :ws do
    empty :halt, emit: :trailing_ws
    on ws, :ws
    for {bquote, size} <- Enum.zip(bquotes, Stream.iterate(6, &(&1-1))) do
      on bquote, "bq#{size}", emit: :ws
    end
    anything :text, emit: :ws
  end

end
