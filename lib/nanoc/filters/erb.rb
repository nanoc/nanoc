module Nanoc::Filters
  class ERBFilter < Nanoc::Filter

    identifiers :erb

    def run(content)
      nanoc_require 'erb'

      # Create context
      assigns = { :page => @page, :pages => @pages, :config => @config, :site => @site }
      context = ::Nanoc::Context.new(assigns)

      # Get result
      ::ERB.new(content).result(context.get_binding)
    end

  end
end
