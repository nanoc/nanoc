module Nanoc::Filters
  # @since 3.2.0
  #
  # @api private
  class Mustache < Nanoc::Filter
    requires 'mustache'

    # Runs the content through
    # [Mustache](http://github.com/defunkt/mustache). This method takes no
    # options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      context = item.attributes.merge({ yield: assigns[:content] })
      ::Mustache.render(content, context)
    end
  end
end
