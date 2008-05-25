module Nanoc::Filters
  class RDoc < Nanoc::Filter

    identifiers :rdoc

    def run(content)
      require 'rdoc/markup/simple_markup'
      require 'rdoc/markup/simple_markup/to_html'

      # Get result
      ::SM::SimpleMarkup.new.convert(content, SM::ToHtml.new)
    end

  end
end
