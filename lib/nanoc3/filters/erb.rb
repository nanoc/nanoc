# encoding: utf-8

module Nanoc3::Filters
  class ERB < Nanoc3::Filter

    # Runs the content through [ERB](http://ruby-doc.org/stdlib/libdoc/erb/rdoc/classes/ERB.html).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'erb'

      # Create context
      context = ::Nanoc3::Context.new(assigns)

      # Get result
      erb = ::ERB.new(content)
      erb.filename = filename
      erb.result(context.get_binding { assigns[:content] })
    end

  end
end
