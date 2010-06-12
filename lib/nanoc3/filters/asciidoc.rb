# encoding: utf-8

module Nanoc3::Filters
  class AsciiDoc < Nanoc3::Filter

    type :text
    identifier :asciidoc

    # Runs the content through [AsciiDoc](http://www.methods.co.nz/asciidoc/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'escape'
      require 'tempfile'

      # Create update thread
      # TODO move this into Filter
      running = true
      update_thread = Thread.new do
        delay = 1.0
        step = 0
        while running
          sleep 0.1

          delay -= 0.1
          next if !$stdout.tty? || delay > 0.05

          $stdout.print 'Running AsciiDoc… ' + %w( | / - \\ )[step] + "\r"
          step = (step + 1) % 4
        end

        if $stdout.tty? && delay < 0.05
          $stdout.print ' ' * 19 + "\r"
        end
      end

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

      # Stop progress bar
      running = false
      update_thread.join

      # Show errors
      puts errors
      raise RuntimeError, errors if !success

      # Done
      output
    rescue Errno::ENOENT => e
      # Stop progress bar
      running = false
      update_thread.join

      # Re-raise
      raise e
    end

  end
end
