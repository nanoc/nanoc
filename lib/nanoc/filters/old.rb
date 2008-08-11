module Nanoc::Filters
  class Old < Nanoc::Filter

    identifiers :eruby, :markdown, :smartypants, :textile

    def run(content)
      raise Nanoc::Error.new(
        "The 'eruby', markdown', 'smartypants' and 'textile' filters no " +
        "longer exist. Instead, use the following filters:\n" +
        "\n" +
        "* for Markdown:      bluecloth, rdiscount, redcloth\n" +
        "* for Textile:       redcloth\n" +
        "* for embedded Ruby: erb, erubis\n" +
        "* for Smartypants:   rubypants"
      )
    end

  end
end
