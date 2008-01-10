module Nanoc::Filter::Old
  class OldFilter < Nanoc::Filter

    identifiers :markdown, :textile, :eruby

    def run(content)
      error "The 'markdown', 'textile' and 'eruby' filters no longer exist. " +
            "Instead, use 'bluecloth' for Markdown, 'redcloth' " +
            "for Markdown or Textile, and 'erb' for eRuby."
    end

  end
end
