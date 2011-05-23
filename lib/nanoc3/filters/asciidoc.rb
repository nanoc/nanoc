# encoding: utf-8

module Nanoc3::Filters
  class AsciiDoc < Nanoc3::Filter

    # Runs the content through [AsciiDoc](http://www.methods.co.nz/asciidoc/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    #
    # @since 3.2.0
    def run(content, params={})
      require 'escape'
      require 'tempfile'

      # Run filter
      output = ''
      errors = ''
      success = true
      Tempfile.open('nanoc-asciidoc-in') do |cmd_in|
        cmd_out = Tempfile.open('nanoc-asciidoc-out')
        cmd_err = Tempfile.open('nanoc-asciidoc-err')
        cmd_out.close
        cmd_err.close

        # Write input
        cmd_in.write(content)
        cmd_in.close

        # Run
        # TODO allow customizable options
        fns = {
          :in  => Escape.shell_single_word(cmd_in.path),
          :out => Escape.shell_single_word(cmd_out.path),
          :err => Escape.shell_single_word(cmd_err.path),
        }
        command = "asciidoc -o #{fns[:out]} #{fns[:in]} 2>#{fns[:err]}"
        system(command)
        success = $?.success?

        # Done
        output = File.read(cmd_out.path)
        errors = File.read(cmd_err.path)
      end

      # Show errors
      puts errors
      raise RuntimeError, errors if !success

      # Done
      output
    end

  end
end
