module Nanoc::Filter::ERBFilter

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

  class ERBFilter < Nanoc::Filter

    names     :erb, :eruby
    requires  'erb'

    def run(content)
      # Create context
      context = ERBContext.new({ :page => @page, :pages => @pages })

      # Get result
      ERB.new(content).result(context.get_binding)
    end

  end

end
