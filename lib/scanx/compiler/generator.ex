defmodule ScanX.Compiler.Generator do
  @doc false
  def emit_scan_definition(transition)
  def emit_scan_definition({:empty, current_state, params}),
    do: emit_empty_state_def(current_state, params)

  def emit_scan_definition({trigger, current_state, %{state: :halt} = params}),
    do: emit_halt_state_def(trigger, current_state, params)

  def emit_scan_definition({trigger, current_state, %{advance: false} = params}),
    do: emit_no_advance_state_def(trigger, current_state, params)

  def emit_scan_definition({:anything, current_state, params}),
    do: emit_advance_any_state_def(current_state, params)

  def emit_scan_definition({grapheme, current_state, params}),
    do: emit_advance_on_state_def(grapheme, current_state, params)


  def convert_part(parts), do: parts |> IO.iodata_to_binary() |> String.reverse()

  def add_token(tokens, {lnb, col}, parts, state) do
    string = parts |> convert_part()
    [{normalize_state(state), string, lnb, col} | tokens]
  end

  def add_token_and_col(tokens, {lnb, col}, parts, state) do
    with [{_, string, _, _} | _] = new_tokens <- add_token(tokens, {lnb, col}, parts, state) do
      {col + String.length(string), new_tokens}
    end
  end

  defp emit_empty_state_def(current_state, params)

  defp emit_empty_state_def(cs, %{emit: nil, state: :halt}) do
    quote do
      def scan(unquote(cs), [], _, _, tokens), do: Enum.reverse(tokens)
      def scanx(unquote(cs), [], _, _, tokens), do: Enum.reverse(tokens)
    end
  end

  defp emit_empty_state_def(cs, %{emit: emit, state: :halt}) do
    quote do
      def scan(unquote(cs), [], lnb_col, parts, tokens),
        do: Enum.reverse(add_token(tokens, lnb_col, parts, unquote(emit)))

      def scanx(unquote(cs), [], lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), []|>Enum.join, 110, parts|>convert_part(), tokens})
        Enum.reverse(add_token(tokens, lnb_col, parts, unquote(emit)))
      end
    end
  end

  defp emit_empty_state_def(cs, %{emit: nil, state: ns}) do
    if (ns || cs) == cs do
      raise "Illegal loop at EOI with state: #{cs}"
    else
      quote do
        def scan(unquote(cs), [], lnb_col, parts, tokens),
          do: scan(unquote(ns), [], lnb_col, parts, tokens)

        def scanx(unquote(cs), [], lnb_col, parts, tokens) do
          IO.inspect({unquote(cs), []|>Enum.join, 125, parts|>convert_part(), tokens})
          scanx(unquote(ns), [], lnb_col, parts, tokens)
        end
      end
    end
  end

  defp emit_empty_state_def(cs, %{emit: emit, state: ns}) do
    if (ns || cs) == cs do
      raise "Illegal loop at EOI with state: #{cs}"
    else
      quote do
        def scan(unquote(cs), [], {lnb, col}, parts, tokens) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          scan(unquote(ns), [], {lnb, nc}, [], nts)
        end

        def scanx(unquote(cs), [], {lnb, col}, parts, tokens) do
          IO.inspect({unquote(cs), []|>Enum.join, 143, parts|>convert_part(), tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          scanx(unquote(ns), [], {lnb, nc}, [], nts)
        end
      end
    end
  end

  defp emit_halt_state_def(trigger, current_state, params)

  defp emit_halt_state_def(_, cs, %{collect: false, emit: nil}) do
    quote do
      def scan(unquote(cs), _, _, _, tokens), do: Enum.reverse(tokens)
      def scanx(unquote(cs), _, _, _, tokens), do: Enum.reverse(tokens)
    end
  end

  defp emit_halt_state_def(_, cs, %{collect: false, emit: emit}) do
    quote do
      def scan(unquote(cs), _, lnb_col, parts, tokens) do
        Enum.reverse(add_token(tokens, lnb_col, parts, unquote(emit)))
      end

      def scanx(unquote(cs), _, lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), "∞", 167, parts|>convert_part(), tokens})
        Enum.reverse(add_token(tokens, lnb_col, parts, unquote(emit)))
      end
    end
  end

  defp emit_halt_state_def(:anything, cs, %{collect: :before, emit: emit}) do
    quote do
      def scan(unquote(cs), [h | _], lnb_col, parts, tokens) do
        Enum.reverse(add_token(tokens, lnb_col, [h | parts], unquote(emit)))
      end

      def scanx(unquote(cs), [h | _], lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), [h, "∞"]|>Enum.join, 180, parts|>convert_part(), tokens})
        Enum.reverse(add_token(tokens, lnb_col, [h | parts], unquote(emit)))
      end
    end
  end

  defp emit_halt_state_def(grapheme, cs, %{collect: :before, emit: emit}) do
    graphemes = String.graphemes(grapheme)

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | _], lnb_col, parts, tokens) do
        Enum.reverse(
          add_token(
            tokens,
            lnb_col,
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            unquote(emit)
          )
        )
      end

      def scanx(unquote(cs), [unquote_splicing(graphemes) | _], lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes), "∞"]|>Enum.join, 202, parts|>convert_part(), tokens})

        Enum.reverse(
          add_token(
            tokens,
            lnb_col,
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            unquote(emit)
          )
        )
      end
    end
  end

  # We assume collect to be false unless it was :before
  defp emit_halt_state_def(grapheme, cs, params) do
    emit_halt_state_def(grapheme, cs, Map.put(params, :collect, :before))
  end

  defp emit_no_advance_state_def(trigger, current_state, params)

  defp emit_no_advance_state_def(_, cs, %{state: nil}) do
    raise("Error looping with no advance in state: #{cs}")
  end

  defp emit_no_advance_state_def(_, cs, %{state: ns}) when ns == cs do
    raise "Error looping with no advance in state: #{cs}"
  end

  defp emit_no_advance_state_def(:anything, cs, %{collect: false, emit: nil, state: ns}) do
    quote do
      def scan(unquote(cs), input, lnb_col, parts, tokens) do
        scan(unquote(ns), input, lnb_col, parts, tokens)
      end

      def scanx(unquote(cs), input, lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), input|>Enum.join, 238, parts|>convert_part(), tokens})
        scanx(unquote(ns), input, lnb_col, parts, tokens)
      end
    end
  end

  defp emit_no_advance_state_def(grapheme, cs, %{collect: false, emit: nil, state: ns}) do
    graphemes = String.graphemes(grapheme)

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | _] = input, lnb_col, parts, tokens) do
        scan(unquote(ns), input, lnb_col, parts, tokens)
      end

      def scanx(unquote(cs), [unquote_splicing(graphemes) | _] = input, lnb_col, parts, tokens) do
        IO.inspect(
          {unquote(cs), [unquote_splicing(graphemes), "∞"]|>Enum.join, 254, parts|>convert_part(), tokens}
        )

        scanx(unquote(ns), input, lnb_col, parts, tokens)
      end
    end
  end

  defp emit_no_advance_state_def(:anything, cs, %{emit: nil, state: ns}) do
    quote do
      def scan(unquote(cs), [head | _] = input, lnb_col, parts, tokens) do
        scan(unquote(ns), input, lnb_col, [head | parts], tokens)
      end

      def scanx(unquote(cs), [head | _] = input, lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), [head, "∞"]|>Enum.join, 269, parts|>convert_part(), tokens})
        scanx(unquote(ns), input, lnb_col, [head | parts], tokens)
      end
    end
  end

  defp emit_no_advance_state_def(grapheme, cs, %{emit: nil, state: ns}) do
    graphemes = String.graphemes(grapheme)

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | _] = input, lnb_col, parts, tokens) do
          scan(
            unquote(ns),
            input,
            lnb_col,
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            tokens
          )
      end

      def scanx(unquote(cs), [unquote_splicing(graphemes) | _] = input, lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes), "∞"]|>Enum.join, 290, parts|>convert_part(), tokens})
        scanx(
          unquote(ns),
          input,
          lnb_col,
          [unquote_splicing(Enum.reverse(graphemes)) | parts],
          tokens
        )
      end
    end
  end

  defp emit_no_advance_state_def(:anything, cs, %{collect: :before, emit: emit, state: ns}) do
    quote do
      def scan(unquote(cs), [head | _] = input, {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head | parts], unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end

      def scanx(unquote(cs), [head | _] = input, {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [head, "∞"]|>Enum.join, 310, parts|>convert_part(), tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head | parts], unquote(emit))
        scanx(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end

  defp emit_no_advance_state_def(grapheme, cs, %{collect: :before, emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens) do
        {nc, nts} =
          add_token_and_col(
            tokens,
            {lnb, col},
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            unquote(emit)
          )

        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end

      def scanx(unquote(cs), [unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes), "∞"]|>Enum.join, 334, parts|>convert_part(), tokens})

        {nc, nts} =
          add_token_and_col(
            tokens,
            {lnb, col},
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            unquote(emit)
          )

        scanx(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end

  defp emit_no_advance_state_def(:anything, cs, %{collect: nil, emit: emit, state: ns}) do
    quote do
      def scan(unquote(cs), input, {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end

      def scanx(unquote(cs), input, {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), input|>Enum.join, 357, parts, tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts|>convert_part(), unquote(emit))
        scanx(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end

  defp emit_no_advance_state_def(grapheme, cs, %{collect: nil, emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end

      def scanx(unquote(cs), [unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes), "∞"]|>Enum.join, 374, parts, tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts|>convert_part(), unquote(emit))
        scanx(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end

  defp emit_no_advance_state_def(:anything, cs, %{emit: emit, state: ns}) do
    quote do
      def scan(unquote(cs), [head | _] = input, {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [head], nts)
      end

      def scanx(unquote(cs), [head | _] = input, {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [head, "∞"]|>Enum.join, 389, parts, tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts|>convert_part(), unquote(emit))
        scanx(unquote(ns), input, {lnb, nc}, [head], nts)
      end
    end
  end

  defp emit_no_advance_state_def(grapheme, cs, %{collect: false, emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [], nts)
      end
      def scanx(unquote(cs), [unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes), "∞" ]|>Enum.join, 405, parts|>convert_part(), tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scanx(unquote(ns), input, {lnb, nc}, [], nts)
      end
    end
  end

  defp emit_no_advance_state_def(grapheme, cs, %{emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scan(unquote(ns), input, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts)
      end

      def scanx(unquote(cs), [unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes), "∞"]|>Enum.join, 422, parts|>convert_part(), tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scanx(unquote(ns), input, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts)
      end
    end
  end

  defp emit_advance_any_state_def(current_state, params)

  defp emit_advance_any_state_def(cs, %{collect: false, emit: nil} = params) do
    ns = Map.get(params, :state) || cs

    quote do
      def scan(unquote(cs), [head | rest], lnb_col, parts, tokens) do
        scan(unquote(ns), rest, lnb_col, parts, tokens)
      end

      def scanx(unquote(cs), [head | rest], lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), [head | rest]|>Enum.join, 440, parts|>convert_part(), tokens})
        scanx(unquote(ns), rest, lnb_col, parts, tokens)
      end
    end
  end

  defp emit_advance_any_state_def(cs, %{emit: nil} = params) do
    ns = Map.get(params, :state) || cs

    quote do
      def scan(unquote(cs), [head | rest], lnb_col, parts, tokens) do
        scan(unquote(ns), rest, lnb_col, [head | parts], tokens)
      end

      def scanx(unquote(cs), [head | rest], lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), [head | rest]|>Enum.join, 455, parts|>convert_part(), tokens})
        scanx(unquote(ns), rest, lnb_col, [head | parts], tokens)
      end
    end
  end

  defp emit_advance_any_state_def(cs, %{collect: :before, emit: emit} = params) do
    ns = Map.get(params, :state) || cs

    quote do
      def scan(unquote(cs), [head | rest], {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head | parts], unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end

      def scanx(unquote(cs), [head | rest], {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [head | rest]|>Enum.join, 471, parts|>convert_part(), tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head | parts], unquote(emit))
        scanx(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end

  defp emit_advance_any_state_def(cs, %{collect: false, emit: emit} = params) do
    ns = Map.get(params, :state) || cs

    quote do
      def scan(unquote(cs), [_ | rest], {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end

      def scanx(unquote(cs), [_ | rest], {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), ["∞" | rest]|>Enum.join, 488, parts|>convert_part(), tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scanx(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end

  defp emit_advance_any_state_def(cs, %{emit: emit} = params) do
    ns = Map.get(params, :state) || cs

    quote do
      def scan(unquote(cs), [head | rest], {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [head], nts)
      end

      def scanx(unquote(cs), [head | rest], {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [head | rest]|>Enum.join, 505, parts|>convert_part(), tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scanx(unquote(ns), rest, {lnb, nc}, [head], nts)
      end
    end
  end

  defp emit_advance_on_state_def(grapheme, current_state, params)

  defp emit_advance_on_state_def(g, cs, %{collect: false, emit: nil} = params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | rest], lnb_col, parts, tokens) do
        scan(unquote(ns), rest, lnb_col, parts, tokens)
      end
      def scanx(unquote(cs), [unquote_splicing(graphemes) | rest], lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes) | rest]|>Enum.join, 523, parts|>convert_part(), tokens})
        scanx(unquote(ns), rest, lnb_col, parts, tokens)
      end
    end
  end

  defp emit_advance_on_state_def(g, cs, %{collect: true, emit: nil} = params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | rest], lnb_col, parts, tokens) do
        scan(
          unquote(ns),
          rest,
          lnb_col,
          [unquote_splicing(Enum.reverse(graphemes)) | parts],
          tokens
        )
      end
      def scanx(unquote(cs), [unquote_splicing(graphemes) | rest], lnb_col, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes) | rest]|>Enum.join, 544, parts|>convert_part(), tokens})
        scanx(
          unquote(ns),
          rest,
          lnb_col,
          [unquote_splicing(Enum.reverse(graphemes)) | parts],
          tokens
        )
      end
    end
  end

  defp emit_advance_on_state_def(g, cs, %{collect: :before, emit: emit} = params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens) do
        {nc, nts} =
          add_token_and_col(
            tokens,
            {lnb, col},
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            unquote(emit)
          )

        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end

      def scanx(unquote(cs), [unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes) | rest]|>Enum.join, 574, parts|>convert_part(), tokens})

        {nc, nts} =
          add_token_and_col(
            tokens,
            {lnb, col},
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            unquote(emit)
          )
        scanx(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end

  defp emit_advance_on_state_def(g, cs, %{collect: false, emit: emit} = params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs

    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [], nts)
      end

      def scanx(unquote(cs), [unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes) | rest]|>Enum.join, 599, parts|>convert_part(), tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scanx(unquote(ns), rest, {lnb, nc}, [], nts)
      end
    end
  end

  defp emit_advance_on_state_def(g, cs, %{emit: emit} = params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state) || cs


    quote do
      def scan(unquote(cs), [unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scan(unquote(ns), rest, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts)
      end

      def scanx(unquote(cs), [unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens) do
        IO.inspect({unquote(cs), [unquote_splicing(graphemes) | rest]|>Enum.join, 617, parts|>convert_part(), tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        scanx(unquote(ns), rest, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts)
      end
    end
  end

  defp normalize_state(state_sym_or_string)
  defp normalize_state(string) when is_binary(string) do
    string |> String.to_atom
  end
  defp normalize_state(sym) when is_atom(sym) do
    sym
  end
  defp normalize_state(anything) do
    raise ArgumentError, "need a symbol or string, not an #{inspect anything}"
  end
end
