defmodule Support.Simple do
  use ScanX

  define_block :halt_on_empty do
    empty :halt, emit: :text
  end

  state :start do
    include :halt_on_empty
    anything :start
  end

  def common_blocks, do: @_common_blocks
end
