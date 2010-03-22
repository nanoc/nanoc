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

      # Get result
      ::Erubis::Eruby.new(content, :filename => filename).result(context.get_binding { assigns[:content] })
    end

  end
end
