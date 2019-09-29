# frozen_string_literal: true

require 'nanoc/core'

module Nanoc
  # @api private
  module CLI
    # Wraps `$stdout` and `$stderr` in appropriate cleaning streams.
    #
    # @return [void]
    def self.setup_cleaning_streams
      $stdout = wrap_in_cleaning_stream($stdout)
      $stderr = wrap_in_cleaning_stream($stderr)
    end

    # Wraps the given stream in a cleaning stream. The cleaning streams will
    # have the proper stream cleaners configured.
    #
    # @param [IO] io The stream to wrap
    #
    # @return [::Nanoc::CLI::CleaningStream]
    def self.wrap_in_cleaning_stream(io)
      cio = ::Nanoc::CLI::CleaningStream.new(io)

      unless enable_utf8?(io)
        cio.add_stream_cleaner(Nanoc::CLI::StreamCleaners::UTF8)
      end

      unless enable_ansi_colors?(io)
        cio.add_stream_cleaner(Nanoc::CLI::StreamCleaners::ANSIColors)
      end

      cio
    end

    # @return [Boolean] true if UTF-8 support is present, false if not
    def self.enable_utf8?(io)
      return true unless io.tty?

      %w[LC_ALL LC_CTYPE LANG].any? { |e| ENV[e] =~ /UTF/i }
    end

    # @return [Boolean] true if color support is present, false if not
    def self.enable_ansi_colors?(io)
      io.tty? && !ENV.key?('NO_COLOR')
    end
  end
end

inflector_class = Class.new(Zeitwerk::Inflector) do
  def camelize(basename, abspath)
    case basename
    when 'version', 'cli', 'utf8'
      basename.upcase
    when 'ansi_colors'
      'ANSIColors'
    else
      super
    end
  end
end

loader = Zeitwerk::Loader.new
loader.inflector = inflector_class.new
loader.push_dir(__dir__ + '/..')
loader.ignore(__dir__ + '/../nanoc-cli.rb')
loader.ignore(__dir__ + '/cli/commands')
loader.setup
loader.eager_load
