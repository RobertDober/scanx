defmodule Scanx.Types do

  defmacro __using__(_options) do
    quote do
      @type grapheme :: binary() | :any

      @type maybe(type) :: nil | type
      @type state_t  :: maybe(atom())

      # Macro output -> Transition representation
      @type collect_t :: :after | :before | false | true
      @type action_params_t :: %{advance: boolean(), collect: collect_t(), emit: state_t(), state: state_t()}
      @type transition :: {state_t(), grapheme(), action_params_t()}
      @type transitions :: list(transition())

      # Intermediate representation
      @type opcode ::  :collect | :collect_all_emit_return | :collect_emit | :collect_emit_return |
                       :emit | :emit_collect | :emit_collect_return |
                       :push | :push_collect | :push_collect_emit | :push_emit | :push_emit_collect |
                       :return |
                       :skip
      @type action :: {opcode(), state_t(), state_t()}
      @type intermediate :: {state_t(), grapheme(), action()} 
      @type intermediates :: list(intermediate())

    end
  end
  
end
