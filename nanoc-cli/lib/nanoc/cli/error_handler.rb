# frozen_string_literal: true

module Nanoc::CLI
  # Catches errors and prints nice diagnostic messages, then exits.
  #
  # @api private
  class ErrorHandler
    # Enables error handling in the given block.
    #
    # @return [void]
    def self.handle_while(exit_on_error: true, &block)
      if @disabled
        yield
      else
        new.handle_while(exit_on_error:, &block)
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
    def handle_while(exit_on_error:)
      # Set exit handler
      %w[INT TERM].each do |signal|
        Signal.trap(signal) do
          puts
          exit(0)
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
    rescue Exception => e # rubocop:disable Lint/RescueException
      # The exception could be wrapped in a
      # Nanoc::Core::Errors::CompilationError, so find the
      # underlying exception and handle that one instead.
      e = unwrap_error(e)

      case e
      when Interrupt
        puts
        exit(1)
      when StandardError, ScriptError
        handle_error(e, exit_on_error:)
      else
        raise e
      end
    end

    def handle_error(error, exit_on_error:)
      if trivial?(error)
        $stderr.puts
        $stderr.puts "Error: #{error.message}"
        resolution = resolution_for(error)
        if resolution
          $stderr.puts
          $stderr.puts resolution
        end
      else
        print_error(error)
      end
      exit(1) if exit_on_error
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
      stream.puts
      stream.puts 'Captain! We’ve been hit!'

      write_error_message(stream, error)
      write_error_detail(stream, error)
      write_item_rep(stream, error)
      write_stack_trace(stream, error)

      stream.puts
      stream.puts 'A detailed crash log has been written to ./crash.log.'
    end

    # Writes a verbose representation of the error on the given stream.
    #
    # @param [Error] error The error that should be described
    #
    # @param [IO] stream The stream to write the description too
    #
    # @return [void]
    def write_verbose_error(error, stream)
      stream.puts "Crash log created at #{Time.now}"

      write_error_message(stream, error, verbose: true)
      write_error_detail(stream, error)
      write_item_rep(stream, error, verbose: true)
      write_stack_trace(stream, error, verbose: true)
      write_version_information(stream, verbose: true)
      write_system_information(stream, verbose: true)
      write_installed_gems(stream, verbose: true)
      write_gemfile_lock(stream, verbose: true)
      write_load_paths(stream, verbose: true)
    end

    # @api private
    def trivial?(error)
      case error
      when Nanoc::Core::TrivialError, Errno::EADDRINUSE
        true
      when LoadError
        GEM_NAMES.key?(gem_name_from_load_error(error))
      else
        false
      end
    end

    protected

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
      'adsf' => 'adsf',
      'asciidoctor' => 'asciidoctor',
      'bluecloth' => 'bluecloth',
      'builder' => 'builder',
      'coderay' => 'coderay',
      'coffee-script' => 'coffee-script',
      'cri' => 'cri',
      'erubi' => 'erubi',
      'erubis' => 'erubis',
      'escape' => 'escape',
      'fog' => 'fog',
      'haml' => 'haml',
      'json' => 'json',
      'kramdown' => 'kramdown',
      'less' => 'less',
      'listen' => 'listen',
      'markaby' => 'markaby',
      'maruku' => 'maruku',
      'mime/types' => 'mime-types',
      'mustache' => 'mustache',
      'nanoc/live' => 'nanoc-live',
      'nokogiri' => 'nokogiri',
      'pandoc-ruby' => 'pandoc-ruby',
      'pry' => 'pry',
      'rack' => 'rack',
      'rack/cache' => 'rack-cache',
      'rainpress' => 'rainpress',
      'rdiscount' => 'rdiscount',
      'redcarpet' => 'redcarpet',
      'redcloth' => 'RedCloth',
      'ruby-handlebars' => 'hbs',
      'rubypants' => 'rubypants',
      'sass' => 'sass',
      'slim' => 'slim',
      'typogruby' => 'typogruby',
      'terser' => 'terser',
      'w3c_validators' => 'w3c_validators',
      'yuicompressor' => 'yuicompressor',
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
        gem_name = gem_name_from_load_error(error)

        if gem_name
          if using_bundler?
            <<~RES
              1. Add `gem '#{gem_name}'` to your Gemfile
              2. Run `bundle install`
              3. Re-run this command
            RES
          else
            "Install the '#{gem_name}' gem using `gem install #{gem_name}`."
          end
        end
      when RuntimeError
        if /^can't modify frozen/.match?(error.message)
          'You attempted to modify immutable data. Some data cannot ' \
          'be modified once compilation has started. Such data includes ' \
          'content and attributes of items and layouts, and filter arguments.'
        end
      when Errno::EADDRINUSE
        'There already is a server running. Either shut down that one, or ' \
        'specify a different port to run this server on.'
      end
    end

    def gem_name_from_load_error(error)
      matches = error.message.match(/(no such file to load|cannot load such file) -- ([^\s]+)/)
      return nil if matches.nil?

      GEM_NAMES[matches[2]]
    end

    def using_bundler?
      defined?(Bundler) && Bundler::SharedHelpers.in_bundle?
    end

    def ruby_version
      RUBY_VERSION
    end

    def write_section_header(stream, title, verbose: false)
      stream.puts

      if verbose
        stream.puts '===== ' + title.upcase + ':'
        stream.puts
      end
    end

    def write_error_message(stream, error, verbose: false)
      write_section_header(stream, 'Message', verbose:)

      error = unwrap_error(error)

      message = "#{error.class}: #{message_for_error(error)}"
      unless verbose
        message = "\e[1m\e[31m" + message + "\e[0m"
      end
      stream.puts message
      resolution = resolution_for(error)
      stream.puts resolution.to_s if resolution
    end

    def message_for_error(error)
      case error
      when JsonSchema::AggregateError
        "\n" + error.errors.map { |e| "  * #{e.pointer}: #{e.message}" }.join("\n")
      else
        error.message
      end
    end

    def write_error_detail(stream, error)
      error = unwrap_error(error)

      if error.respond_to?(:full_message)
        stream.puts
        stream.puts error.full_message
      end
    end

    def write_item_rep(stream, error, verbose: false)
      return unless error.is_a?(Nanoc::Core::Errors::CompilationError)

      write_section_header(stream, 'Item being compiled', verbose:)

      item_rep = error.item_rep
      stream.puts "Current item: #{item_rep.item.identifier} (#{item_rep.name.inspect} representation)"
    end

    def write_stack_trace(stream, error, verbose: false)
      write_section_header(stream, 'Stack trace', verbose:)

      writer = Nanoc::CLI::StackTraceWriter.new(stream)
      writer.write(unwrap_error(error), verbose:)
    end

    def write_version_information(stream, verbose: false)
      write_section_header(stream, 'Version information', verbose:)
      stream.puts Nanoc::Core.version_information
    end

    def write_system_information(stream, verbose: false)
      uname = `uname -a`
      write_section_header(stream, 'System information', verbose:)
      stream.puts uname
    rescue Errno::ENOENT
    end

    def write_installed_gems(stream, verbose: false)
      write_section_header(stream, 'Installed gems', verbose:)
      gems_and_versions.each do |g|
        stream.puts "  #{g.first} #{g.last.join(', ')}"
      end
    end

    def write_gemfile_lock(stream, verbose: false)
      if File.exist?('Gemfile.lock')
        write_section_header(stream, 'Gemfile.lock', verbose:)
        stream.puts File.read('Gemfile.lock')
      end
    end

    def write_load_paths(stream, verbose: false)
      write_section_header(stream, 'Load paths', verbose:)
      $LOAD_PATH.each_with_index do |i, index|
        stream.puts "  #{index}. #{i}"
      end
    end

    def unwrap_error(e)
      case e
      when Nanoc::Core::Errors::CompilationError
        e.unwrap
      else
        e
      end
    end
  end
end
