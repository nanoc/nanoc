module Nanoc::Filters
  class Erubis < Nanoc::Filter

    identifiers :eruby

    def run(content)
      nanoc_require 'erubis'

      # Get assigns
      assigns = @other_assigns.merge({ :page => @page, :pages => @pages, :layouts => @layouts, :config => @config, :site => @site })

      # Get result
      ::Erubis::Eruby.new(content).evaluate(assigns)
    end

  end
end
