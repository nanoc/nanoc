module Nanoc::Filters
  class RDoc < Nanoc::Filter

    identifier :rdoc

    def run(content)
      require 'rdoc/markup'
      require 'rdoc/markup/to_html'

      # Get result
      ::RDoc::Markup.new.convert(content, ::RDoc::Markup::ToHtml.new)
    end

  end
end
