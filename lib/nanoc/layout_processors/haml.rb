module Nanoc::LayoutProcessor::Haml

  class Context

    def initialize(hash)
      hash.each_pair do |key, value|
        instance_variable_set('@' + key.to_s, value)
      end
    end

    def get_binding
      binding
    end

  end

  class HamlLayoutProcessor < Nanoc::LayoutProcessor

    identifiers :haml
    extensions  '.haml'

    def run(content)
      nanoc_require 'haml'

      # Get options
      options = @page.haml_options || {}

      # Get assigns/locals
      assigns = { :page => @page, :pages => @pages, :config => @config, :site => @site }
      context = Context.new(assigns)

      # Get result
      ::Haml::Engine.new(content, options).render(context, assigns)
    end

  end

end
