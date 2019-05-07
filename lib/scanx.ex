defmodule ScanX do
  alias ScanX.Compiler.Actions
  alias ScanX.Compiler.Generator

  defmacro __before_compile__(env) do
    # IO.puts env.module
    # IO.puts "================================="
    definitions =
      Module.get_attribute(env.module, :_transitions)
      |> Enum.reverse
      |> List.flatten
      |> Enum.map(&Generator.emit_scan_definition/1)

    if System.get_env("DEBUG_MACROS") do
      definitions
      |> Macro.to_string()
      |> IO.puts()
    end

    quote do
      unquote_splicing(definitions)
    end
  end

  defmacro __using__(_options) do
    quote do
      @before_compile unquote(__MODULE__)
      import unquote(__MODULE__)
      import unquote(__MODULE__.Compiler.Actions)
      import unquote(__MODULE__.Compiler.Generator)

      def scan_document(doc, options \\ []) do
        doc
        |> String.split(~r{\r\n?|\n})
        |> Enum.zip(Stream.iterate(1, &(&1 + 1)))
        |> Enum.flat_map(&scan_line(&1, Keyword.get(options, :debug, false)))
      end

      def scan_line(linelnb_tuple, debug \\ false)
      def scan_line({line, lnb}, false), do: scan__start({String.graphemes(line), {lnb, 1}, [], []})
      def scan_line({line, lnb}, true), do: scanx__start({String.graphemes(line), {lnb, 1}, [], []})

      Module.register_attribute(__MODULE__, :_transitions, accumulate: true)
      Module.register_attribute(__MODULE__, :_current_state, accumulate: false)
    end
  end

  defmacro state(state_id, code)
  defmacro state(state_id, do: block) when is_binary(state_id) do
    atom_state_id = state_id
      |> String.to_atom
    quote do
      Module.put_attribute(__MODULE__, :_current_state, unquote(atom_state_id))
      unquote(block)
      Module.put_attribute(__MODULE__, :_current_state, nil)
    end
  end
  defmacro state(state_id, do: block) do
    quote do
      Module.put_attribute(__MODULE__, :_current_state, unquote(state_id))
      unquote(block)
      Module.put_attribute(__MODULE__, :_current_state, nil)
    end
  end

  defmacro anything(state, params \\ []) do
    quote do
      current_state = Module.get_attribute(__MODULE__, :_current_state)
      @_transitions Actions.add_transition(:anything, unquote(state), unquote(params), current_state)
    end
  end
  defmacro empty(state, params \\ []) do
    quote do
      current_state = Module.get_attribute(__MODULE__, :_current_state)
      @_transitions Actions.add_transition(:empty, unquote(state), unquote(params), current_state)
    end
  end
  defmacro on(grapheme, state, params \\ []) do
    quote do
      current_state = Module.get_attribute(__MODULE__, :_current_state)
      @_transitions Actions.add_transition(unquote(grapheme), unquote(state), unquote(params), current_state)
    end
  end

  # defmacro on_any(graph_list, state, params \\ []), do: Actions.add_transition_for_any(graph_list, state, params)
end
