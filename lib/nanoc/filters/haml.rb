module Nanoc::Filters
  class HamlFilter < Nanoc::Filter

    identifiers :haml

    def run(content)
      nanoc_require 'haml'

      # Get options
      options = @page.haml_options || {}

      # Get assigns/locals
      assigns = { :page => @page, :pages => @pages, :config => @config, :site => @site }
      context = ::Nanoc::Context.new(assigns)

      # Get result
      ::Haml::Engine.new(content, options).render(context, assigns)
    end

  end
end
