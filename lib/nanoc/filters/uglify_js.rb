# encoding: utf-8

require 'uglifier'

module Nanoc::Filters
  class UglifyJS < Nanoc::Filter

    # Runs the content through [UglifyJS](https://github.com/mishoo/UglifyJS/).
    # This method optionally takes options to pass directly to Uglifier:
    #
    #     {
    #       :mangle => true, # Mangle variables names
    #       :toplevel => false, # Mangle top-level variable names
    #       :except => [], # Variable names to be excluded from mangling
    #       :max_line_length => 32 * 1024, # Maximum line length
    #       :squeeze => true, # Squeeze code resulting in smaller, but less-readable code
    #       :seqs => true, # Reduce consecutive statements in blocks into single statement
    #       :dead_code => true, # Remove dead code (e.g. after return)
    #       :unsafe => false, # Optimizations known to be unsafe in some situations
    #       :copyright => true, # Show copyright message
    #       :beautify => false, # Ouput indented code
    #       :beautify_options => {
    #         :indent_level => 4,
    #         :indent_start => 0,
    #         :quote_keys => false,
    #         :space_colon => 0,
    #         :ascii_only => false
    #       }
    #     }
    #
    # @param [String] content The content to filter
    #
    # @option params [Array] :options ([]) A list of options to pass on to Uglifier
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Add filename to load path
      Uglifier.new(params).compile(content)
    end

  end
end
