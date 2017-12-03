# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Erubis < Nanoc::Filter
    identifier :erubis

    requires 'erubis'

    # Runs the content through [Erubis](http://www.kuwata-lab.com/erubis/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      # Create context
      context = ::Nanoc::Int::Context.new(assigns)

      # Get binding
      proc = assigns[:content] ? -> { assigns[:content] } : nil
      assigns_binding = context.get_binding(&proc)

      # Get result
      erubis_with_erbout.new(content, filename: filename).result(assigns_binding)
    end

    private

    def erubis_with_erbout
      @_erubis_with_erbout ||= Class.new(::Erubis::Eruby) { include ::Erubis::ErboutEnhancer }
    end
  end
end
