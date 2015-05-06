# encoding: utf-8

module Nanoc::Filters
  # @since 3.2.0
  #
  # @api private
  class AsciiDoc < Nanoc::Filter
    # Runs the content through [AsciiDoc](http://www.methods.co.nz/asciidoc/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      stdout = StringIO.new
      stderr = $stderr
      piper = Nanoc::Extra::Piper.new(stdout: stdout, stderr: stderr)
      piper.run(%w( asciidoc -o - - ), content)
      stdout.string
    end
  end
end
