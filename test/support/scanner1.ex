defmodule Support.Scanner1 do
  use Scanx

  ws = [" ", "\t"]
  state :start do
    on ws, :ws
    anything :word
  end

  state :word do
    empty :halt, emit: :word
    on ws, :ws, emit: :word
    anything :word
  end

  state :ws do
    empty :halt, emit: :ws
    on ws, :ws
    anything :word, emit: :ws
  end
end
