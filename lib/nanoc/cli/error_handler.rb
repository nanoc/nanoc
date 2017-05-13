# frozen_string_literal: true

module Nanoc::CLI
  # Catches errors and prints nice diagnostic messages, then exits.
  #
  # @api private
  class ErrorHandler
    # @param [Nanoc::CLI::Command, nil] command The command that is
    #   currently being executed, or nil if there is none
    def initialize(command: nil)
      @command = command
    end

    # Enables error handling in the given block.
    #
    # @param [Nanoc::CLI::Command, nil] command The command that is
    #   currently being executed, or nil if there is none
    #
    # @return [void]
    def self.handle_while(command: nil, &block)
      if @disabled
        yield
      else
        new(command: command).handle_while(&block)
      end
    end

    # Disables error handling. This is used by the test cases to prevent error
    # from being handled by the CLI while tests are running.
    def self.disable
      @disabled = true
    end

    # Re-enables error handling after it was disabled. This is used by the test
    # cases to prevent error from being handled by the CLI while tests are
    # running.
    def self.enable
      @disabled = false
    end

    # Enables error handling in the given block. This method should not be
    # called directly; use {Nanoc::CLI::ErrorHandler.handle_while} instead.
    #
    # @return [void]
    def handle_while(&_block)
      # Set exit handler
      %w[INT TERM].each do |signal|
        Signal.trap(signal) do
          puts
          exit!(0)
        end
      end

      # Set stack trace dump handler
      if !defined?(RUBY_ENGINE) || RUBY_ENGINE != 'jruby'
        begin
          Signal.trap('USR1') do
            puts 'Caught USR1; dumping a stack trace'
            puts caller.map { |i| "  #{i}" }.join("\n")
          end
        rescue ArgumentError
        end
      end

      # Run
      yield
    rescue Nanoc::Int::Errors::GenericTrivial => e
      $stderr.puts "Error: #{e.message}"
      exit(1)
    rescue Interrupt
      exit(1)
    rescue StandardError, ScriptError => e
      print_error(e)
      exit(1)
    end

    # Prints the given error to stderr. Includes message, possible resolution
    # (see {#resolution_for}), compilation stack, backtrace, etc.
    #
    # @param [Error] error The error that should be described
    #
    # @return [void]
    def self.print_error(error)
      new.print_error(error)
    end

    # Prints the given error to stderr. Includes message, possible resolution
    # (see {#resolution_for}), compilation stack, backtrace, etc.
    #
    # @param [Error] error The error that should be described
    #
    # @return [void]
    def print_error(error)
      write_compact_error(error, $stderr)

      File.open('crash.log', 'w') do |io|
        cio = Nanoc::CLI.wrap_in_cleaning_stream(io)
        cio.add_stream_cleaner(::Nanoc::CLI::StreamCleaners::ANSIColors)
        write_verbose_error(error, cio)
      end
    end

    # Writes a compact representation of the error, suitable for a terminal, on
    # the given stream (probably stderr).
    #
    # @param [Error] error The error that should be described
    #
    # @param [IO] stream The stream to write the description too
    #
    # @return [void]
    def write_compact_error(error, stream)
      # Header
      stream.puts
      stream.puts 'Captain! We’ve been hit!'

      # Sections
      write_error_message(stream, error)
      write_item_rep(stream, error)
      write_stack_trace(stream, error)

      # Issue link
      write_issue_link(stream)
    end

    # Writes a verbose representation of the error on the given stream.
    #
    # @param [Error] error The error that should be described
    #
    # @param [IO] stream The stream to write the description too
    #
    # @return [void]
    def write_verbose_error(error, stream)
      # Header
      stream.puts "Crashlog created at #{Time.now}"

      # Sections
      write_error_message(stream, error, verbose: true)
      write_item_rep(stream, error, verbose: true)
      write_stack_trace(stream, error, verbose: true)
      write_version_information(stream, verbose: true)
      write_system_information(stream, verbose: true)
      write_installed_gems(stream, verbose: true)
      write_gemfile_lock(stream, verbose: true)
      write_load_paths(stream, verbose: true)
    end

    protected

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @see Nanoc::CLI.debug?
    def debug?
      Nanoc::CLI.debug?
    end

    # @return [Nanoc::Int::Site] The site that is currently being processed
    def site
      @command && @command.site
    end

    # @return [Nanoc::Int::Compiler] The compiler for the current site
    def compiler
      site && site.compiler
    end

    # @return [Hash<String, Array>] A hash containing the gem names as keys and gem versions as value
    def gems_and_versions
      gems = {}
      Gem::Specification.find_all.sort_by { |s| [s.name, s.version] }.each do |spec|
        gems[spec.name] ||= []
        gems[spec.name] << spec.version.to_s
      end
      gems
    end

    # A hash that contains the name of the gem for a given required file. If a
    # `#require` fails, the gem name is looked up in this hash.
    GEM_NAMES = {
      'adsf'           => 'adsf',
      'bluecloth'      => 'bluecloth',
      'builder'        => 'builder',
      'coderay'        => 'coderay',
      'cri'            => 'cri',
      'erubi'          => 'erubi',
      'erubis'         => 'erubis',
      'escape'         => 'escape',
      'fog'            => 'fog',
      'haml'           => 'haml',
      'handlebars'     => 'hbs',
      'json'           => 'json',
      'kramdown'       => 'kramdown',
      'less'           => 'less',
      'listen'         => 'listen',
      'markaby'        => 'markaby',
      'maruku'         => 'maruku',
      'mime/types'     => 'mime-types',
      'nokogiri'       => 'nokogiri',
      'nokogumbo'      => 'nokogumbo',
      'pry'            => 'pry',
      'rack'           => 'rack',
      'rack/cache'     => 'rack-cache',
      'rainpress'      => 'rainpress',
      'rdiscount'      => 'rdiscount',
      'redcarpet'      => 'redcarpet',
      'redcloth'       => 'RedCloth',
      'rubypants'      => 'rubypants',
      'sass'           => 'sass',
      'w3c_validators' => 'w3c_validators',
    }.freeze

    # Attempts to find a resolution for the given error, or nil if no
    # resolution can be automatically obtained.
    #
    # @param [Error] error The error to find a resolution for
    #
    # @return [String] The resolution for the given error
    def resolution_for(error)
      error = unwrap_error(error)

      case error
      when LoadError
        # Get gem name
        matches = error.message.match(/(no such file to load|cannot load such file) -- ([^\s]+)/)
        return nil if matches.nil?
        gem_name = GEM_NAMES[matches[2]]

        # Build message
        if gem_name
          if using_bundler?
            'Make sure the gem is added to Gemfile and run `bundle install`.'
          else
            "Install the '#{gem_name}' gem using `gem install #{gem_name}`."
          end
        end
      when RuntimeError
        if error.message =~ /^can't modify frozen/
          'You attempted to modify immutable data. Some data cannot ' \
          'be modified once compilation has started. Such data includes ' \
          'content and attributes of items and layouts, and filter arguments.'
        end
      end
    end

    def using_bundler?
      defined?(Bundler) && Bundler::SharedHelpers.in_bundle?
    end

    def write_section_header(stream, title, verbose: false)
      stream.puts
      if verbose
        stream.puts '===== ' + title.upcase + ':'
      else
        stream.puts "\e[1m\e[31m" + title + ':' + "\e[0m"
      end
      stream.puts
    end

    def write_error_message(stream, error, verbose: false)
      write_section_header(stream, 'Message', verbose: verbose)

      error = unwrap_error(error)

      stream.puts "#{error.class}: #{error.message}"
      resolution = resolution_for(error)
      stream.puts resolution.to_s if resolution
    end

    def write_item_rep(stream, error, verbose: false)
      return unless error.is_a?(Nanoc::Int::Errors::CompilationError)

      write_section_header(stream, 'Item being compiled', verbose: verbose)

      item_rep = error.item_rep
      stream.puts "Item identifier: #{item_rep.item.identifier}"
      stream.puts "Item rep name:   #{item_rep.name.inspect}"
    end

    def write_stack_trace(stream, error, verbose: false)
      write_section_header(stream, 'Stack trace', verbose: verbose)

      error = unwrap_error(error)

      count = verbose ? -1 : 10
      error.backtrace[0...count].each_with_index do |item, index|
        stream.puts "  #{index}. #{item}"
      end
      if !verbose && error.backtrace.size > count
        stream.puts "  ... #{error.backtrace.size - count} more lines omitted. See full crash log for details."
      end
    end

    def write_issue_link(stream, _params = {})
      stream.puts
      stream.puts 'If you believe this is a bug in Nanoc, please do report it at'
      stream.puts '-> https://github.com/nanoc/nanoc/issues/new <-'
      stream.puts
      stream.puts 'A detailed crash log has been written to ./crash.log.'
    end

    def write_version_information(stream, verbose: false)
      write_section_header(stream, 'Version information', verbose: verbose)
      stream.puts Nanoc.version_information
    end

    def write_system_information(stream, verbose: false)
      uname = `uname -a`
      write_section_header(stream, 'System information', verbose: verbose)
      stream.puts uname
    rescue Errno::ENOENT
    end

    def write_installed_gems(stream, verbose: false)
      write_section_header(stream, 'Installed gems', verbose: verbose)
      gems_and_versions.each do |g|
        stream.puts "  #{g.first} #{g.last.join(', ')}"
      end
    end

    def write_gemfile_lock(stream, verbose: false)
      if File.exist?('Gemfile.lock')
        write_section_header(stream, 'Gemfile.lock', verbose: verbose)
        stream.puts File.read('Gemfile.lock')
      end
    end

    def write_load_paths(stream, verbose: false)
      write_section_header(stream, 'Load paths', verbose: verbose)
      $LOAD_PATH.each_with_index do |i, index|
        stream.puts "  #{index}. #{i}"
      end
    end

    def unwrap_error(e)
      case e
      when Nanoc::Int::Errors::CompilationError
        e.unwrap
      else
        e
      end
    end
  end
end
