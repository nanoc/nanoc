module Nanoc::LayoutProcessor::Haml
  class HamlLayoutProcessor < Nanoc::LayoutProcessor

    identifiers :haml
    extensions  '.haml'

    def run(content)
      nanoc_require 'haml'

      options = @page[:haml_options] || {}
      options[:locals] = { :page => @page, :pages => @pages, :config => @config, :site => @site }

      ::Haml::Engine.new(content, options).to_html
    end

  end
end
