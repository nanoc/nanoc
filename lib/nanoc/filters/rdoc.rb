module Nanoc::Filters
  class RDocFilter < Nanoc::Filter

    identifiers :rdoc

    def run(content)
      nanoc_require 'rdoc/markup/simple_markup'
      nanoc_require 'rdoc/markup/simple_markup/to_html'

      ::SM::SimpleMarkup.new.convert(content, SM::ToHtml.new)
    end

  end
end
