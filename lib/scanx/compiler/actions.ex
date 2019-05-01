defmodule Scanx.Compiler.Actions do
  
  @default_params %{
    advance: true,
    collect: true,
    emit: nil,
    state: nil
  }

  @doc false
  def add_transition(trigger, state, params)
  def add_transition(:empty, state, _params) when is_list(state) do
    _add_transition(:empty, Keyword.put_new(state, :state, :halt))
  end
  def add_transition(trigger, state, _params) when is_list(state) do
    _add_transition(trigger, state)
  end
  def add_transition(trigger, state, params) do
    _add_transition(trigger, Keyword.put(params, :state, state))
  end

  @doc false
  def emit_scan_definition(transition)
  def emit_scan_definition({:empty, current_state, params}), do:
    emit_empty_state_def(current_state, params)
  def emit_scan_definition({trigger, current_state, %{state: :halt} = params}), do:
    emit_halt_state_def(trigger, current_state, params)
  def emit_scan_definition({trigger, current_state, %{advance: false} = params}), do:
    emit_no_advance_state_def(trigger, current_state, params)
  def emit_scan_definition({:anything, current_state, params}), do:
    emit_advance_any_state_def(current_state, params)
  def emit_scan_definition({grapheme, current_state, params}), do:
    emit_advance_on_state_def(grapheme, current_state, params)

  defp _add_transition(trigger, params) do
    params =
    if is_list(params) do
      params|>Enum.into(@default_params)
    else
      params
    end

    params = 
    if Map.get(params, :emit) do
      Map.put_new(params, :collect, :before)
    else
      params
    end
    _add_one_or_many(trigger, params)
  end

  def _add_one_or_many(trigger, params) do
    quote bind_quoted: [params: Macro.escape(params), trigger: trigger] do
      current_state = Module.get_attribute(__MODULE__, :_current_state)
      if current_state == nil do
        # raise "Must not call `#{unquote(macro_name_of_trigger(trigger))}` macro outside of state macro"
        raise "Must not call #{trigger} macro outside of state macro"
      end
      case trigger do
        [_|_] -> Enum.map(trigger, &(@_transitions {&1, current_state, params}))
        _     -> @_transitions {trigger, current_state, params}
      end
    end
  end

  defp macro_name_of_trigger(trigger)
  defp macro_name_of_trigger(trigger) when is_binary(trigger) do
    "on"
  end
  defp macro_name_of_trigger(trigger), do: trigger


  def add_token(tokens, {lnb, col}, part, state) do
    string = part |> IO.iodata_to_binary() |> String.reverse()
    [{state, string, lnb, col} | tokens]
  end

  def add_token_and_col(tokens, {lnb, col}, part, state) do
    with [{_, string, _, _} | _] = new_tokens <- add_token(tokens, {lnb, col}, part, state) do
      {col + String.length(string), new_tokens}
    end
  end


  defp emit_empty_state_def(current_state, params)
  defp emit_empty_state_def(cs, %{emit: nil, state: :halt}) do
    quote do
      def scan(unquote(cs), [], _, _, tokens), do: Enum.reverse(tokens)
    end
  end
  defp emit_empty_state_def(cs, %{emit: emit, state: :halt}) do
    quote do
      def scan(unquote(cs), [], lnb_col, part, tokens), do: Enum.reverse(add_token(tokens, lnb_col, part, unquote(emit)))
    end
  end
  defp emit_empty_state_def(cs, %{emit: nil, state: ns}) do
    if (ns || cs) == cs do
      raise "Illegal loop at EOI with state: #{cs}"
    else
      quote do
        def scan(unquote(cs), [], lnb_col, part, tokens), do: scan(unquote(ns), [], lnb_col, part, tokens)
      end
    end
  end
  defp emit_empty_state_def(cs, %{emit: emit, state: ns}) do
    if (ns || cs) == cs do
      raise "Illegal loop at EOI with state: #{cs}"
    else
      quote do
        def scan(unquote(cs), [], {lnb, col}, part, tokens) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
          scan(unquote(ns), [], {lnb, nc}, [], nts)
        end
      end
    end
  end

  defp emit_halt_state_def(trigger, current_state, params)
  defp emit_halt_state_def(_, cs, %{collect: false, emit: nil}) do
    quote do
      def scan(unquote(cs), _, _, _, tokens), do: Enum.reverse(tokens)
    end
  end
  defp emit_halt_state_def(_, cs, %{collect: false, emit: emit}) do
    quote do
      def scan(unquote(cs), _, lnb_col, parts, tokens), do: Enum.reverse(add_token(tokens, lnb_col, parts, unquote(emit)))
    end
  end
  defp emit_halt_state_def(:anything, cs, %{collect: :before, emit: emit}) do
    quote do
      def scan(unquote(cs), [h|_], lnb_col, parts, tokens), do:
        Enum.reverse(add_token(tokens, lnb_col, [h|parts], unquote(emit)))
    end
  end
  defp emit_halt_state_def(grapheme, cs, %{collect: :before, emit: emit}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_], lnb_col, parts, tokens) do
        Enum.reverse(add_token(tokens, lnb_col, [unquote_splicing(Enum.reverse(graphemes))|parts], unquote(emit)))
      end
    end
  end
  # We assume collect to be false unless it was :before
  defp emit_halt_state_def(grapheme, cs, params) do
    emit_halt_state_def(grapheme, cs, Map.put(params, :collect, :before))
  end
    
  defp emit_no_advance_state_def(trigger, current_state, params)
  defp emit_no_advance_state_def(_, cs, %{state: nil}), do: raise "Error looping with no advance in state: #{cs}"
  defp emit_no_advance_state_def(_, cs, %{state: ns}) when ns == cs do
    raise "Error looping with no advance in state: #{cs}"
  end
  defp emit_no_advance_state_def(:anything, cs, %{collect: false, emit: nil, state: ns}) do
    quote do
      def scan(unquote(cs), input, lnb_col, part, tokens), do: scan(unquote(ns), input, lnb_col, part, tokens)
    end
  end
  defp emit_no_advance_state_def(grapheme, cs, %{collect: false, emit: nil, state: ns}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_]=input, lnb_col, part, tokens), do: scan(unquote(ns), input, lnb_col, part, tokens)
    end
  end
  defp emit_no_advance_state_def(:anything, cs, %{emit: nil, state: ns}) do
    quote do
      def scan(unquote(cs), [head|_]=input, lnb_col, part, tokens), do: scan(unquote(ns), input, lnb_col, [head|part], tokens)
    end
  end
  defp emit_no_advance_state_def(grapheme, cs, %{emit: nil, state: ns}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_]=input, lnb_col, part, tokens), do: scan(unquote(ns), input, lnb_col, [unquote_splicing(Enum.reverse(graphemes))|part], tokens)
    end
  end
  defp emit_no_advance_state_def(:anything, cs, %{collect: :before, emit: emit, state: ns}) do
    quote do
      def scan(unquote(cs), [head|_]=input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head|part], unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_no_advance_state_def(grapheme, cs, %{collect: :before, emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_]=input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [unquote_splicing(Enum.reverse(graphemes))|part], unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_no_advance_state_def(:anything, cs, %{collect: nil, emit: emit, state: ns}) do
    quote do
      def scan(unquote(cs), input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_no_advance_state_def(grapheme, cs, %{collect: nil, emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_]=input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_no_advance_state_def(:anything, cs, %{emit: emit, state: ns}) do
    quote do
      def scan(unquote(cs), [head|_]=input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [head], nts)
      end
    end
  end
  defp emit_no_advance_state_def(grapheme, cs, %{emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|_]=input, {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts)
      end
    end
  end
    
  defp emit_advance_any_state_def(current_state, params)
  defp emit_advance_any_state_def(cs, %{collect: false, emit: nil}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], lnb_col, part, tokens), do: scan(unquote(ns), rest, lnb_col, part, tokens)
    end
  end
  defp emit_advance_any_state_def(cs, %{emit: nil}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], lnb_col, part, tokens), do: scan(unquote(ns), rest, lnb_col, [head|part], tokens)
    end
  end
  defp emit_advance_any_state_def(cs, %{collect: :before, emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head|part], unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_advance_any_state_def(cs, %{collect: false, emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [_|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_advance_any_state_def(cs, %{emit: emit}=params) do
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [head|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [head], nts)
      end
    end
  end

  defp emit_advance_on_state_def(grapheme, current_state, params)
  defp emit_advance_on_state_def(g, cs, %{collect: false, emit: nil}=params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|rest], lnb_col, part, tokens), do:
        scan(unquote(ns), rest, lnb_col, part, tokens)
    end
  end
  defp emit_advance_on_state_def(g, cs, %{collect: true, emit: nil}=params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|rest], lnb_col, part, tokens), do:
        scan(unquote(ns), rest, lnb_col, [unquote_splicing(Enum.reverse(graphemes))|part], tokens)
    end
  end
  defp emit_advance_on_state_def(g, cs, %{collect: :before, emit: emit}=params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [unquote_splicing(Enum.reverse(graphemes))|part], unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_advance_on_state_def(g, cs, %{collect: false, emit: emit}=params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end
  defp emit_advance_on_state_def(g, cs, %{emit: emit}=params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs
    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes)|rest], {lnb, col}, part, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, part, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts)
      end
    end
  end

end
