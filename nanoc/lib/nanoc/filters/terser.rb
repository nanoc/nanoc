# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Terser < Nanoc::Filter
    identifier :terser
    identifier :uglify_js

    requires 'terser'

    # Runs the content through [terser](https://github.com/ahorek/terser-ruby).
    # This method optionally takes options to pass directly to Terser.
    #
    # @param [String] content The content to filter
    #
    # @option params [Array] :options ([]) A list of options to pass on to Terser
    #
    # @return [String] The filtered content
    def run(content, params = {})
      # Add filename to load path
      ::Terser.new(params).compile(content)
    end
  end
end
