defmodule Support.MarkdownTest do

  defmacro __using__(_options) do
    quote do
      use ExUnit.Case
      import Support.ScanHelper

      def scan(line) do
        Support.Markdown.scan_document(line)
      end
    end
  end
end
