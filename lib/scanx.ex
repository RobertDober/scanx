defmodule Scanx do


  alias Scanx.Compiler.Actions

  defmacro __before_compile__(env) do
    # IO.puts env.module
    # IO.puts "================================="
    definitions = 
    Module.get_attribute(env.module, :_transitions) 
    |> Enum.reverse
    |> Enum.map(&Actions.emit_scan_definition/1)

    if System.get_env("DEBUG_MACROS") do
      definitions
      |> Macro.to_string
      |> IO.puts
    end
    quote do
      def scan(nil, nil, 0, nil, nil), do: []
      defoverridable scan: 5
      unquote_splicing(definitions)
    end
  end

  defmacro __using__(_options) do
    quote do
      @before_compile unquote(__MODULE__)
      import unquote(__MODULE__)
      import unquote(__MODULE__.Compiler.Actions)
      def scan_document(doc) do
        doc
        |> String.split(~r{\r\n?|\n})
        |> Enum.zip(Stream.iterate(1, &(&1 + 1)))
        |> Enum.flat_map(&scan_line/1)
      end

      def scan_line({line, lnb}), do:
        scan(:start, String.graphemes(line), {lnb, 1}, [], [])
      Module.register_attribute __MODULE__, :_transitions, accumulate: true
      Module.register_attribute __MODULE__, :_current_state, accumulate: false
    end
  end


  defmacro state(state_id, do: block) do
    quote do
      Module.put_attribute __MODULE__, :_current_state, unquote(state_id)
      unquote(block)
      Module.put_attribute __MODULE__, :_current_state, nil
    end
  end

  defmacro anything(state, params \\ []), do: Actions.add_transition(:anything, state, params)
  defmacro empty(state, params \\ []), do: Actions.add_transition(:empty, state, params)
  defmacro on(grapheme, state, params \\ []), do: Actions.add_transition(grapheme, state, params)
  # defmacro on_any(graph_list, state, params \\ []), do: Actions.add_transition_for_any(graph_list, state, params)

end
