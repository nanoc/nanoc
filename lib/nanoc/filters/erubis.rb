# encoding: utf-8

module Nanoc::Filters
  # @api private
  class Erubis < Nanoc::Filter
    requires 'erubis'

    # The same as `::Erubis::Eruby` but adds `_erbout` as an alias for the
    # `_buf` variable, making it compatible with nanoc’s helpers that rely
    # on `_erbout`, such as {Nanoc::Helpers::Capturing}.
    class ErubisWithErbout < ::Erubis::Eruby
      include ::Erubis::ErboutEnhancer
    end

    # Runs the content through [Erubis](http://www.kuwata-lab.com/erubis/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      # Create context
      context = ::Nanoc::Context.new(assigns)

      # Get binding
      proc = assigns[:content] ? -> { assigns[:content] } : nil
      assigns_binding = context.get_binding(&proc)

      # Get result
      ErubisWithErbout.new(content, filename: filename).result(assigns_binding)
    end
  end
end
