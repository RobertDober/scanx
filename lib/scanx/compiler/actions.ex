defmodule ScanX.Compiler.Actions do
  @default_params %{
    advance: true,
    collect: true,
    emit: nil,
    state: nil
  }

  @doc false
  def add_transition(trigger, state, params, current_state)
  def add_transition(:empty, state, _params, current_state) when is_list(state) do
    _add_transition(:empty, Keyword.put_new(state, :state, :halt), current_state)
  end
  def add_transition(trigger, state, _params, current_state) when is_list(state) do
    _add_transition(trigger, state, current_state)
  end
  def add_transition(trigger, state, params, current_state) when is_binary(state) do
    _add_transition(trigger, Keyword.put(params, :state, String.to_atom(state)), current_state)
  end
  def add_transition(trigger, state, params, current_state) do
    _add_transition(trigger, Keyword.put(params, :state, state), current_state)
  end

  defp _add_transition(trigger, params, current_state) do
    params =
      params |> Enum.into(@default_params)

    params =
      if Map.get(params, :emit) do
        Map.put_new(params, :collect, :before)
      else
        params
      end

    _add_one_or_many(trigger, params, current_state)
  end

  def _add_one_or_many(trigger, params, current_state) do
      if current_state == nil do
        # raise "Must not call `#{unquote(macro_name_of_trigger(trigger))}` macro outside of state macro"
        raise "Must not call #{trigger} macro outside of state macro"
      end

      case trigger do
        [_ | _] -> Enum.map(trigger, &{&1, current_state, params})
        _ -> {trigger, current_state, params}
      end
  end

  defp macro_name_of_trigger(trigger)
  defp macro_name_of_trigger(trigger) when is_binary(trigger) do
    "on"
  end
  defp macro_name_of_trigger(trigger), do: trigger

end
