defmodule Support.Scanner1 do
  use Scanx


  state :start do
    empty emit: :blank
    on " ", state: :indent
    anything state: :main, advance: false
  end

  state :indent do
    empty emit: :blank
    on " ", state: :indent1
    anything state: :main, advance: false
  end

  state :indent1 do
    empty emit: :blank
  end
end
