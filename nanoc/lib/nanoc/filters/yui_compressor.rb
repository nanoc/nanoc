# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class YUICompressor < Nanoc::Filter
    identifier :yui_compressor

    requires 'yuicompressor'

    # Compress Javascript or CSS using [YUICompressor](http://rubydoc.info/gems/yuicompressor).
    # This method optionally takes options to pass directly to the
    # YUICompressor gem.
    #
    # @param [String] content JavaScript or CSS input
    #
    # @param [Hash] params Options passed to YUICompressor
    #
    # @return [String] Compressed but equivalent JavaScript or CSS
    def run(content, params = {})
      ::YUICompressor.compress(content, params)
    end
  end
end
