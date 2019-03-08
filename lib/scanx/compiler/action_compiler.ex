defmodule Scanx.Compiler.ActionCompiler do
  
  use Scanx.Types

  @moduledoc """
  Computes the intermediate representation of the action, that is the RHS of the
  definition of the scan function

  Therefore in an eventual

          defp scan(:indent, [" "=head|rest], col, partial, tokens), do:
              scan(:indent, rest, col [head|partial], tokens)

  The function body will be generated from the intermediate code's action triple which, in this case
  would be:

          {:collect, :indent, nil}

  Where `:indent`  represents the next state, and `nil` the emit state not used her

  An example of emitting a token would look like the following

          defp scan(:indent, input, col, partial, tokens), do:
              scan(:after_indent, input, col+length(to_string(partial), [], [{:indent, to_string(partial), col}|tokens])

  would have been created from the following action

          {:push_emit, :after_indent, indent}
  """

  @doc false
  @spec compute_empty_action( action_params_t() ) :: action() 
  def compute_empty_action(actions)
  def compute_empty_action(%{emit: false, state: :halt}), do: {:return, nil, nil}
  def compute_empty_action(%{emit: emit,  state: :halt}), do: {:emit_return, nil, emit}
  def compute_empty_action(%{emit: false, state: state}), do: {:skip, state, nil}
  def compute_empty_action(%{emit: emit,  state: state}), do: {:emit, state, emit}

  @doc false
  @spec compute_action(action_params_t()) :: action() 
  def compute_action(actions)
  def compute_action(%{state: :halt}=actions), do: compute_halt_action(actions)
  def compute_action(%{advance: false}=actions), do: compute_no_advance_action(actions)
  def compute_action(actions), do: compute_advance_action(actions)


  @spec compute_halt_action(action_params_t()) :: action() 
  defp compute_halt_action(actions)
  defp compute_halt_action(%{emit: false}), do: {:return, nil, nil}
  defp compute_halt_action(%{collect: :before, emit: emit}), do:
    {:collect_emit_return, nil, emit}
  defp compute_halt_action(%{emit: emit}), do: {:emit_return, nil, emit}

  @spec compute_no_advance_action(action_params_t()) :: action() 
  defp compute_no_advance_action(actions)
  defp compute_no_advance_action(%{state: nil}), do: {:push, nil, nil} # Loop detection is elsewhere
  defp compute_no_advance_action(%{collect: false, emit: false, state: state}), do:
    {:push, state, nil}
  defp compute_no_advance_action(%{collect: true, emit: false, state: state}), do:
    {:push_collect, state, nil}
  defp compute_no_advance_action(%{collect: false, emit: emit, state: state}), do:
    {:push, state, emit}
  defp compute_no_advance_action(%{collect: :before, emit: emit, state: state}), do:
    {:push_collect_emit, state, emit}
  defp compute_no_advance_action(%{collect: :after, emit: emit, state: state}), do:
    {:push_emit_collect, state, emit}


  @spec compute_advance_action(action_params_t()) :: action() 
  defp compute_advance_action(actions)
  defp compute_advance_action(%{collect: false, emit: nil, state: state}), do:
    {:skip, state, nil}
  defp compute_advance_action(%{collect: true, emit: nil, state: state}), do:
    {:collect, state, nil}
  defp compute_advance_action(%{collect: false, emit: emit, state: state}), do:
    {:emit, state, emit}
  defp compute_advance_action(%{collect: :before, emit: emit, state: state}), do:
    {:collect_emit, state, emit}
  defp compute_advance_action(%{collect: :after, emit: emit, state: state}), do:
    {:emit_collect, state, emit}



end
