module Nanoc::Filters
  class RDoc < Nanoc::Filter

    identifiers :rdoc

    def run(content)
      # Load requirements
      nanoc_require 'rdoc/markup/simple_markup'
      nanoc_require 'rdoc/markup/simple_markup/to_html'

      # Get result
      ::SM::SimpleMarkup.new.convert(content, SM::ToHtml.new)
    end

  end
end
