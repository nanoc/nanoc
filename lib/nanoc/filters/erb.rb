module Nanoc::Filter::ERB

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

  class ERBFilter < Nanoc::Filter

    identifiers :erb, :eruby

    def run(content)
      nanoc_require 'erb'

      # Create context
      assigns = { :page => @page, :pages => @pages, :config => @config, :site => @site }
      context = Context.new(assigns)

      # Get result
      ::ERB.new(content).result(context.get_binding)
    end

  end

end
