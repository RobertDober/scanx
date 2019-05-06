defmodule ScanX.Compiler.Generator do
  @doc false
  def emit_scan_definition({_, current_state, _}=transition) do
    case emit_scan_def_wo_current_state(transition) do
      {code, new_state}  -> { code, new_state }
      code               -> { code, current_state }
    end
      |> change_scan_name(current_state)
  end


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

  defp emit_scan_def_wo_current_state(transition)
  defp emit_scan_def_wo_current_state({:empty, _, params}),
    do: emit_empty_state_def(params)
  defp emit_scan_def_wo_current_state({trigger, _, %{state: :halt} = params}),
    do: emit_halt_state_def(trigger, params)
  defp emit_scan_def_wo_current_state({trigger, _, %{advance: false} = params}),
    do: emit_no_advance_state_def(trigger, params)
  defp emit_scan_def_wo_current_state({:anything, _, params}),
    do: emit_advance_any_state_def(params)
  defp emit_scan_def_wo_current_state({grapheme, _, params}),
    do: emit_advance_on_state_def(grapheme, params)

  defp emit_empty_state_def(params)
  defp emit_empty_state_def(%{emit: nil, state: :halt}) do
    quote do
      def __def_scan__({[], _, _, tokens}), do: Enum.reverse(tokens)
      def __def_scan__x({[], _, _, tokens}), do: Enum.reverse(tokens)
    end
  end
  defp emit_empty_state_def(%{emit: emit, state: :halt}) do
    quote do
      def __def_scan__({[], lnb_col, parts, tokens}),
        do: Enum.reverse(add_token(tokens, lnb_col, parts, unquote(emit)))

      def __def_scan__x({[], lnb_col, parts, tokens}) do
        IO.inspect({[]|>Enum.join, 50, parts|>convert_part(), tokens})
        Enum.reverse(add_token(tokens, lnb_col, parts, unquote(emit)))
      end
    end
  end
  defp emit_empty_state_def(%{emit: nil, state: ns}) do
    {
      quote do
        def __def_scan__({[], lnb_col, parts, tokens}),
          do: __call_scan__({[], lnb_col, parts, tokens})

        def __def_scan__x([], lnb_col, parts, tokens) do
          IO.inspect({[]|>Enum.join, 62, parts|>convert_part(), tokens})
          __call_scan__x({[], lnb_col, parts, tokens})
        end
      end,
      ns
    }
  end
  defp emit_empty_state_def(%{emit: emit, state: ns}) do
    {
      quote do
        def __def_scan__({[], {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__({[], {lnb, nc}, [], nts})
        end

        def __def_scan__x({[], {lnb, col}, parts, tokens}) do
          IO.inspect({"", 78, parts|>convert_part(), tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__x({[], {lnb, nc}, [], nts})
        end
      end,
        ns
      }
  end

  defp emit_halt_state_def(trigger, params)
  defp emit_halt_state_def(_, %{collect: false, emit: nil}) do
    quote do
      def __def_scan__({_, _, _, tokens}), do: Enum.reverse(tokens)
      def __def_scan__x({_, _, _, tokens}), do: Enum.reverse(tokens)
    end
  end

  defp emit_halt_state_def(_, %{collect: false, emit: emit}) do
    quote do
      def __def_scan__({_, lnb_col, parts, tokens}) do
        Enum.reverse(add_token(tokens, lnb_col, parts, unquote(emit)))
      end

      def __def_scan__x({_, lnb_col, parts, tokens}) do
        IO.inspect({"∞", 102, parts|>convert_part(), tokens})
        Enum.reverse(add_token(tokens, lnb_col, parts, unquote(emit)))
      end
    end
  end

  defp emit_halt_state_def(:anything, %{collect: :before, emit: emit}) do
    quote do
      def __def_scan__({[h | _], lnb_col, parts, tokens}) do
        Enum.reverse(add_token(tokens, lnb_col, [h | parts], unquote(emit)))
      end

      def __def_scan__x({[h | _], lnb_col, parts, tokens}) do
        IO.inspect({[h, "∞"]|>Enum.join, 115, parts|>convert_part(), tokens})
        Enum.reverse(add_token(tokens, lnb_col, [h | parts], unquote(emit)))
      end
    end
  end
  defp emit_halt_state_def(grapheme, %{collect: :before, emit: emit}) do
    graphemes = String.graphemes(grapheme)

    quote do
      def __def_scan__({[unquote_splicing(graphemes) | _], lnb_col, parts, tokens}) do
        Enum.reverse(
          add_token(
            tokens,
            lnb_col,
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            unquote(emit)
          )
        )
      end

      def __def_scan__x({[unquote_splicing(graphemes) | _], lnb_col, parts, tokens}) do
        IO.inspect({[unquote_splicing(graphemes), "∞"]|>Enum.join, 136, parts|>convert_part(), tokens})

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
  defp emit_halt_state_def(grapheme, params) do
    emit_halt_state_def(grapheme, Map.put(params, :collect, :before))
  end

  defp emit_no_advance_state_def(trigger, params)
  defp emit_no_advance_state_def(:anything, %{collect: false, emit: nil, state: ns}) do
    {
      quote do
      def __def_scan__({input, lnb_col, parts, tokens}) do
      __call_scan__({input, lnb_col, parts, tokens})
      end
        def __def_scan__x({input, lnb_col, parts, tokens}) do
          IO.inspect({input|>Enum.join, 161, parts|>convert_part(), tokens})
          __call_scan__x({input, lnb_col, parts, tokens})
        end
      end,
      ns
    }
  end
  defp emit_no_advance_state_def(grapheme, %{collect: false, emit: nil, state: ns}) do
    graphemes = String.graphemes(grapheme)
    {
      quote do
        def __def_scan__({[unquote_splicing(graphemes) | _] = input, lnb_col, parts, tokens}) do
        __call_scan__({input, lnb_col, parts, tokens})
        end

        def __def_scan__x({[unquote_splicing(graphemes) | _] = input, lnb_col, parts, tokens}) do
          IO.inspect({[unquote_splicing(graphemes), "∞"]|>Enum.join, 177, parts|>convert_part(), tokens})
          __call_scan__x({input, lnb_col, parts, tokens})
        end
      end,
      ns
    }
  end
  defp emit_no_advance_state_def(:anything, %{emit: nil, state: ns}) do
    {
      quote do
        def __def_scan__({[head | _] = input, lnb_col, parts, tokens}) do
          __call_scan__({input, lnb_col, [head | parts], tokens})
        end

        def __def_scan__x({[head | _] = input, lnb_col, parts, tokens}) do
          IO.inspect({[head, "∞"]|>Enum.join, 192, parts|>convert_part(), tokens})
          __call_scan__x({input, lnb_col, [head | parts], tokens})
        end
      end,
      ns
    }
  end
  defp emit_no_advance_state_def(grapheme, %{emit: nil, state: ns}) do
    graphemes = String.graphemes(grapheme)

    {
      quote do
        def __def_scan__({[unquote_splicing(graphemes) | _] = input, lnb_col, parts, tokens}) do
            __call_scan__({
              input,
              lnb_col,
              [unquote_splicing(Enum.reverse(graphemes)) | parts],
              tokens
            })
        end

        def __def_scan__x({[unquote_splicing(graphemes) | _] = input, lnb_col, parts, tokens}) do
          IO.inspect({[unquote_splicing(graphemes), "∞"]|>Enum.join, 214, parts|>convert_part(), tokens})
          __call_scan__x({
            input,
            lnb_col,
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            tokens
          })
        end
      end,
      ns
    }
  end
  defp emit_no_advance_state_def(:anything, %{collect: :before, emit: emit, state: ns}) do
    {
      quote do
        def __def_scan__({[head | _] = input, {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head | parts], unquote(emit))
          __call_scan__({input, {lnb, nc}, [], nts})
        end

        def __def_scan__x({[head | _] = input, {lnb, col}, parts, tokens}) do
          IO.inspect({[head, "∞"]|>Enum.join, 235, parts|>convert_part(), tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head | parts], unquote(emit))
          __call_scan__x({input, {lnb, nc}, [], nts})
        end
      end,
      ns
    }
  end
  defp emit_no_advance_state_def(grapheme, %{collect: :before, emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)
    {
      quote do
      def __def_scan__({[unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens}) do
      {nc, nts} =
        add_token_and_col(
          tokens,
          {lnb, col},
          [unquote_splicing(Enum.reverse(graphemes)) | parts],
          unquote(emit)
        )

      __call_scan__({input, {lnb, nc}, [], nts})
      end

        def __def_scan__x({[unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens}) do
          io.inspect({[unquote_splicing(graphemes), "∞"]|>enum.join, 334, parts|>convert_part(), tokens})

          {nc, nts} =
            add_token_and_col(
              tokens,
              {lnb, col},
              [unquote_splicing(Enum.reverse(graphemes)) | parts],
              unquote(emit)
            )

          __call_scan__x({input, {lnb, nc}, [], nts})
        end
      end,
      ns
      }
  end
  defp emit_no_advance_state_def(:anything, %{collect: nil, emit: emit, state: ns}) do
    {
    quote do
      def __def_scan__({input, {lnb, col}, parts, tokens}) do
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
        __call_scan__({input, {lnb, nc}, [], nts})
      end

      def __def_scan__x({input, {lnb, col}, parts, tokens}) do
        IO.inspect({input|>Enum.join, 285, parts, tokens})
        {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts|>convert_part(), unquote(emit))
        __call_scan__x({input, {lnb, nc}, [], nts})
      end
    end,
    ns
    }
  end
  defp emit_no_advance_state_def(grapheme, %{collect: nil, emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)

    {
      quote do
        def __def_scan__({[unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__({input, {lnb, nc}, [], nts})
        end

        def __def_scan__x({[unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens}) do
          IO.inspect({[unquote_splicing(graphemes), "∞"]|>Enum.join, 304, parts, tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts|>convert_part(), unquote(emit))
          __call_scan__x({input, {lnb, nc}, [], nts})
        end
      end,
      ns
    }
  end
  defp emit_no_advance_state_def(:anything, %{emit: emit, state: ns}) do
    {
      quote do
        def __def_scan__({[head | _] = input, {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__({input, {lnb, nc}, [head], nts})
        end

        def __def_scan__x([head | _] = input, {lnb, col}, parts, tokens) do
          IO.inspect({[head, "∞"]|>Enum.join, 321, parts, tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts|>convert_part(), unquote(emit))
          __call_scan__x({input, {lnb, nc}, [head], nts})
        end
      end,
      ns
    }
  end
  defp emit_no_advance_state_def(grapheme, %{collect: false, emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)

    {
      quote do
        def __def_scan__({[unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__({input, {lnb, nc}, [], nts})
        end
        def __def_scan__x({[unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens}) do
          IO.inspect({[unquote_splicing(graphemes), "∞" ]|>Enum.join, 339, parts|>convert_part(), tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__x({input, {lnb, nc}, [], nts})
        end
      end,
      ns
    }
  end
  defp emit_no_advance_state_def(grapheme, %{emit: emit, state: ns}) do
    graphemes = String.graphemes(grapheme)

    {
      quote do
        def __def_scan__({[unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__({input, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts})
        end

        def __def_scan__x({[unquote_splicing(graphemes) | _] = input, {lnb, col}, parts, tokens}) do
          IO.inspect({[unquote_splicing(graphemes), "∞"]|>Enum.join, 358, parts|>convert_part(), tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__x({input, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts})
        end
      end,
      ns
    }
  end

  defp emit_advance_any_state_def(params)
  defp emit_advance_any_state_def(%{collect: false, emit: nil} = params) do
    ns = Map.get(params, :state)

    {
      quote do
        def __def_scan__({[head | rest], lnb_col, parts, tokens}) do
          __call_scan__({rest, lnb_col, parts, tokens})
        end

        def __def_scan__x({[head | rest], lnb_col, parts, tokens}) do
          IO.inspect({[head | rest]|>Enum.join, 378, parts|>convert_part(), tokens})
          __call_scan__x({rest, lnb_col, parts, tokens})
        end
      end,
      ns
    }
  end

  defp emit_advance_any_state_def(%{emit: nil} = params) do
    ns = Map.get(params, :state)

    {
      quote do
        def __def_scan__({[head | rest], lnb_col, parts, tokens}) do
          __call_scan__({rest, lnb_col, [head | parts], tokens})
        end

        def __def_scan__x({[head | rest], lnb_col, parts, tokens}) do
          IO.inspect({[head | rest]|>Enum.join, 396, parts|>convert_part(), tokens})
          __call_scan__x({rest, lnb_col, [head | parts], tokens})
        end
      end,
      ns
    }
  end

  defp emit_advance_any_state_def(%{collect: :before, emit: emit} = params) do
    ns = Map.get(params, :state)

    {
      quote do
        def __def_scan__({[head | rest], {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head | parts], unquote(emit))
          __call_scan__({rest, {lnb, nc}, [], nts})
        end

        def __def_scan__x({[head | rest], {lnb, col}, parts, tokens}) do
          IO.inspect({[head | rest]|>Enum.join, 415, parts|>convert_part(), tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, [head | parts], unquote(emit))
          __call_scan__x({rest, {lnb, nc}, [], nts})
        end
      end,
      ns
    }
  end

  defp emit_advance_any_state_def(%{collect: false, emit: emit} = params) do
    ns = Map.get(params, :state)

    {
      quote do
        def __def_scan__({[_ | rest], {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__({rest, {lnb, nc}, [], nts})
        end

        def __def_scan__x({[_ | rest], {lnb, col}, parts, tokens}) do
          IO.inspect({["∞" | rest]|>Enum.join, 435, parts|>convert_part(), tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__x({rest, {lnb, nc}, [], nts})
        end
      end,
      ns
    }
  end

  defp emit_advance_any_state_def(%{emit: emit} = params) do
    ns = Map.get(params, :state)

    {
      quote do
        def __def_scan__({[head | rest], {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__({rest, {lnb, nc}, [head], nts})
        end

        def __def_scan__x({[head | rest], {lnb, col}, parts, tokens}) do
          IO.inspect({[head | rest]|>Enum.join, 455, parts|>convert_part(), tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__x({rest, {lnb, nc}, [head], nts})
        end
      end,
      ns
    }
  end

  defp emit_advance_on_state_def(grapheme, params)
  defp emit_advance_on_state_def(g, %{collect: false, emit: nil} = params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state)

    {
      quote do
        def __def_scan__({[unquote_splicing(graphemes) | rest], lnb_col, parts, tokens}) do
          __call_scan__({rest, lnb_col, parts, tokens})
        end
        def __def_scan__x({[unquote_splicing(graphemes) | rest], lnb_col, parts, tokens}) do
          IO.inspect({[unquote_splicing(graphemes) | rest]|>Enum.join, 475, parts|>convert_part(), tokens})
          __call_scan__x({rest, lnb_col, parts, tokens})
        end
      end,
      ns
    }
  end

  defp emit_advance_on_state_def(g, %{collect: true, emit: nil} = params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state)

    {
      quote do
        def __def_scan__({[unquote_splicing(graphemes) | rest], lnb_col, parts, tokens}) do
          __call_scan__({
            rest,
            lnb_col,
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            tokens
          })
        end
        def __def_scan__x({[unquote_splicing(graphemes) | rest], lnb_col, parts, tokens}) do
          IO.inspect({[unquote_splicing(graphemes) | rest]|>Enum.join, 498, parts|>convert_part(), tokens})
          __call_scan__x({
            rest,
            lnb_col,
            [unquote_splicing(Enum.reverse(graphemes)) | parts],
            tokens
          })
        end
      end,
      ns
    }
  end

  defp emit_advance_on_state_def(g, %{collect: :before, emit: emit} = params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state)

    {
      quote do
        def __def_scan__({[unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens}) do
          {nc, nts} =
            add_token_and_col(
              tokens,
              {lnb, col},
              [unquote_splicing(Enum.reverse(graphemes)) | parts],
              unquote(emit)
            )

          __call_scan__({rest, {lnb, nc}, [], nts})
        end

        def __def_scan__x({[unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens}) do
          IO.inspect({[unquote_splicing(graphemes) | rest]|>Enum.join, 530, parts|>convert_part(), tokens})

          {nc, nts} =
            add_token_and_col(
              tokens,
              {lnb, col},
              [unquote_splicing(Enum.reverse(graphemes)) | parts],
              unquote(emit)
            )
          __call_scan__x({rest, {lnb, nc}, [], nts})
        end
      end,
      ns
      }
  end

  defp emit_advance_on_state_def(g, %{collect: false, emit: emit} = params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state)

    {
      quote do
        def __def_scan__({[unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__({rest, {lnb, nc}, [], nts})
        end

        def __def_scan__x({[unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens}) do
          IO.inspect({[unquote_splicing(graphemes) | rest]|>Enum.join, 558, parts|>convert_part(), tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__x({rest, {lnb, nc}, [], nts})
        end
      end,
      ns
    }
  end

  defp emit_advance_on_state_def(g, %{emit: emit} = params) do
    graphemes = String.graphemes(g)
    ns = Map.get(params, :state)

    {
      quote do
        def __def_scan__({[unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens}) do
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__({rest, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts})
        end

        def __def_scan__x({[unquote_splicing(graphemes) | rest], {lnb, col}, parts, tokens}) do
          IO.inspect({[unquote_splicing(graphemes) | rest]|>Enum.join, 579, parts|>convert_part(), tokens})
          {nc, nts} = add_token_and_col(tokens, {lnb, col}, parts, unquote(emit))
          __call_scan__x({rest, {lnb, nc}, [unquote_splicing(Enum.reverse(graphemes))], nts})
        end
      end,
      ns
    }
  end

  # When generating the basic AST we create placeholders for the eventual function names
  # These placeholders are:
  #        `__def_scan__`, `__def_scan__x`,  `__call_scan__` and `__call_scan__x`
  # In this step the definition stubs are replaced by
  #        `scan__<current_state>` and `scanx__<current_state>`
  # while the call stubs are replaced by
  #        `scan__<next_state>`  and `scanx__<next_state>`
  defp change_scan_name({ast, new_state}, current_state) do
    ast
    |> Macro.postwalk(&_change_scan_name(&1, new_state, current_state))
  end
  defp _change_scan_name(node, new_state, current_state)
  defp _change_scan_name({:__def_scan__, context, args}, _, cs) do
    {String.to_atom("scan__#{cs}"), context, args}
  end
  defp _change_scan_name({:__def_scan__x, context, args}, _, cs) do
    {String.to_atom("scanx__#{cs}"), context, args}
  end
  defp _change_scan_name({:__call_scan__, context, args}, ns, _) do
    {String.to_atom("scan__#{ns}"), context, args}
  end
  defp _change_scan_name({:__call_scan__x, context, args}, ns, _) do
    {String.to_atom("scanx__#{ns}"), context, args}
  end
  defp _change_scan_name(any, _, _) do
    any
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
