# encoding: utf-8

module Nanoc::Filters
  # @api private
  class UglifyJS < Nanoc::Filter
    requires 'uglifier'

    # Runs the content through [UglifyJS](https://github.com/mishoo/UglifyJS2/).
    # This method optionally takes options to pass directly to Uglifier.
    #
    # @param [String] content The content to filter
    #
    # @option params [Array] :options ([]) A list of options to pass on to Uglifier
    #
    # @return [String] The filtered content
    def run(content, params = {})
      # Add filename to load path
      Uglifier.new(params).compile(content)
    end
  end
end
