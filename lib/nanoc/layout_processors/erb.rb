module Nanoc::LayoutProcessors

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
      assigns = @other_assigns.merge({ :page => @page, :pages => @pages, :config => @config, :site => @site })
      context = ERBContext.new(assigns)

      # Get result
      ::ERB.new(layout).result(context.get_binding)
    end

  end

end
