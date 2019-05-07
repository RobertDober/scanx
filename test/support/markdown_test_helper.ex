defmodule Support.MarkdownTestHelper do

  defmacro __using__(_options) do
    quote do
      use ExUnit.Case
      import Support.ScanHelper

      def scan(line) do
        Support.Markdown.scan_document(line)
      end
      def scanx(line) do
        Support.Markdown.scan_document(line, debug: true)
      end
    end
  end
end
