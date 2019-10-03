defmodule Dev.Debug do
  @moduledoc false

  # only inspect element if the env variable DEBUG contains the
  # string `trigger`
  def debug(trigger, data, as_string \\ false) do
    unless String.contains?(System.get_env("DEBUG", ""), trigger), do: return
  end

end
