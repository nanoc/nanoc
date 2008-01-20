module Nanoc::LayoutProcessors
  class HamlLayoutProcessor < Nanoc::LayoutProcessor

    identifiers :haml
    extensions  '.haml'

    def run(layout)
      nanoc_require 'haml'

      # Get options
      options = @page.haml_options || {}

      # Get assigns/locals
      assigns = @other_assigns.merge({ :page => @page, :pages => @pages, :config => @config, :site => @site })
      context = ::Nanoc::Context.new(assigns)

      # Get result
      ::Haml::Engine.new(layout, options).render(context, assigns)
    end

  end
end
