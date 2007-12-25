module Nanoc::Filter::Old
  class OldFilter < Nanoc::Filter

    identifiers :markdown, :textile

    def run(content)
      error "The 'markdown' and 'textile' filters no longer exist. " +
            "Instead, use 'bluecloth' for Markdown, and 'redcloth' " +
            "for Markdown or Textile formatting."
    end

  end
end
