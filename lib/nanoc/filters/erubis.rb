module Nanoc::Filters
  class ErubisFilter < Nanoc::Filter

    identifiers :eruby

    def run(content)
      nanoc_require 'erubis'

      # Get assigns
      assigns = { :page => @page, :pages => @pages, :config => @config, :site => @site }

      # Get result
      Erubis::Eruby.new(content).evaluate(assigns)
    end

  end
end
