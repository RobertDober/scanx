# defmodule Support.Combine do
#   use ScanX

#   ws = [" ", "\t", "\n"]
#   kwds = ["do", "end", "for"]

#   state :start do
#     empty(:halt)
#     on(kwds, :kwd)
#     on(ws, :ws)
#     anything(:text)
#   end

#   state :kwd do
#     empty :halt, emit: :kwd
#     on ws, :ws, emit: :kwd
#     anything :text
#   end

#   state :text do
#     empty(:halt, emit: :text)
#     on(ws, :ws, emit: :text)
#     anything(:text)
#   end

#   state :ws do
#     empty(:halt, emit: :ws)
#     on(ws, :ws)
#     on(kwds, :kwd, emit: :ws)
#     anything(:text, emit: :ws)
#   end
# end
