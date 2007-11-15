module Nanoc::LayoutProcessor::ERBLayoutProcessor

  class ERBContext

    def initialize(hash)
      hash.each_pair do |key, value|
        instance_variable_set('@' + key.to_s, value)
      end
    end

    def get_binding
      binding
    end

  end

  class ERBLayoutProcessor < Nanoc::LayoutProcessor

    identifiers  :erb, :eruby
    extensions   '.erb', '.rhtml'

    def run(layout)
      nanoc_require 'erb'
      
      # Create context
      context = ERBContext.new({ :page => @page, :pages => @pages, :config => @config, :site => @site })

      # Get result
      ERB.new(layout).result(context.get_binding)
    end

  end

end

def render(name, context={})
  layout = @site.layouts.find { |l| l[:name] == name }
  layout_processor_class = Nanoc::PluginManager.layout_processor_for_extension(layout[:extension])
  layout_processor = layout_processor_class.new(@page, @pages, @site.config, @site)
  layout_processor.run(layout[:content])
end
