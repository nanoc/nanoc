module Nanoc::Filters
  class Haml < Nanoc::Filter

    identifiers :haml
    extensions  '.haml'

    def run(content)
      nanoc_require 'haml'

      # Get options
      options = @page.haml_options || {}

      # Get assigns/locals
      assigns = @other_assigns.merge({ :page => @page, :pages => @pages, :layouts => @layouts, :config => @config, :site => @site })
      context = ::Nanoc::Context.new(assigns)

      # Get result
      ::Haml::Engine.new(content, options).render(context, assigns)
    end

  end
end
