# encoding: utf-8

require 'systemu'

module Nanoc::Filters

  # @since 3.2.0
  class AsciiDoc < Nanoc::Filter

    # Runs the content through [AsciiDoc](http://www.methods.co.nz/asciidoc/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Run command
      stdout = ''
      stderr = ''
      status = systemu(
        [ 'asciidoc', '-o', '-', '-' ],
        'stdin'  => content,
        'stdout' => stdout,
        'stderr' => stderr)

      # Show errors
      unless status.success?
        $stderr.puts stderr
        raise RuntimeError, "AsciiDoc filter failed with status #{status}"
      end

      # Get result
      stdout
    end

  end

end
