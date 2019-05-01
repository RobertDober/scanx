# defmodule MakeList do

#   defmacro __before_compile__(env) do
#     Module.get_attribute(env.module, :_list) 
#     |> IO.inspect
#   end

#   defmacro __using__(_options) do
#     quote do
#       @before_compile unquote(__MODULE__)
#       import unquote(__MODULE__)
#       Module.register_attribute __MODULE__, :_list, accumulate: true

#     end
#   end

#   defmacro list_entry(value) do
#     quote do
#       @_list unquote(value)
#     end
#   end
# end
