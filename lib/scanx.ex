defmodule Scanx do

  alias Scanx.Compiler.Pass1

  @moduledoc """
  Implements a DSL to define a State Machine based Scanner

  Given the following module

        defmodule MyScanner do
          use Scanx

          state :start do
            empty emit: :blank
            on " ", state: indent1
            anything state: :command, advance: false
          end

          state :indent1 do
            empty emit: :blank
            on " ", state: indent2
            anything state: :command, advance: false
          end

          state :indent2 do
            empty emit: :blank
            anything state: :comment, advance: false
          end

          state :command do
            on :alpha, state: :command1 # predefined set
            on "; ", state: :comment
          end
  """

  defmacro __before_compile__(env) do
    definitions = 
    Module.get_attribute(env.module, :_transitions) 
    |> Pass1.transform
    |> IO.inspect

    quote do
      def scan(transition)
      def scan(:undefined), do: []
      # unquote(definitions)
    end
  end

  defmacro __using__(_options) do
    quote do
      @before_compile unquote(__MODULE__)
      import unquote(__MODULE__)
      def scan_line(line), do:
      scan({:start, String.graphemes(line), 1, [], []})
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

  defmacro anything(params), do: add_transition(:anything, params, true)
  defmacro empty(params), do: add_transition(:empty, Keyword.merge(params, state: :halt))
  defmacro on(head, params), do: add_transition(:on, params, head)
  defmacro rest(params), do: add_transition(:rest, Keyword.merge(params, state: :halt), :rest)


  @default_params %{
    advance: true,
    collect: true,
    emit: nil,
    state: nil
  }
  defp add_transition(trans_type, params \\ [], head \\ nil) do
    params1 =
      params|>Enum.into(@default_params)|>Macro.escape

    quote do
      current_state = Module.get_attribute(__MODULE__, :_current_state)
      if current_state == nil do
        raise "Must not call #{unquote(trans_type)} outside of state macro"
      end
      @_transitions {current_state, unquote(head), unquote(params1)}
    end
  end

end
