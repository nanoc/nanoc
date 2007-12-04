module Nanoc::Filter::Markdown
  class MarkdownFilter < Nanoc::Filter

    identifiers :markdown, :bluecloth

    def run(content)
      nanoc_require 'bluecloth'

      ::BlueCloth.new(content).to_html
    end

  end
end
