# encoding: utf-8

module Nanoc3::Filters
  class Erubis < Nanoc3::Filter

    # Runs the content through [Erubis](http://www.kuwata-lab.com/erubis/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'erubis'

      # Create context
      context = ::Nanoc3::Context.new(assigns)

      # Get binding
      proc = assigns[:content] ? lambda { assigns[:content] } : nil
      assigns_binding = context.get_binding(&proc)

      # Get result
      ::Erubis::Eruby.new(content, :filename => filename).result(assigns_binding)
    end

  end
end
