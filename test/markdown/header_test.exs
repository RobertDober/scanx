defmodule Markdown.HeaderTest do
  use ExUnit.Case
  alias Support.Markdown, as: S

  describe "headers" do
    test "h6" do
      assert S.scan_document("###### ") == [{:h6, "####### ", {1, 1}}]
    end
  end
end
