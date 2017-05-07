module Nanoc::Filters
  # @api private
  class Slim < Nanoc::Filter
    identifier :slim

    requires 'slim'

    # Runs the content through [Slim](http://slim-lang.com/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      params = {
        disable_capture: true, # Capture managed by Nanoc
        buffer: '_erbout', # Force slim to output to the buffer used by Nanoc
      }.merge params

      # Create context
      context = ::Nanoc::Int::Context.new(assigns)

      ::Slim::Template.new(filename, params) { content }.render(context) { assigns[:content] }
    end
  end
end
