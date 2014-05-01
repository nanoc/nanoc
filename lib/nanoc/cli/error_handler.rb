# encoding: utf-8

module Nanoc::CLI

  # Catches errors and prints nice diagnostic messages, then exits.
  #
  # @api private
  class ErrorHandler

    # @option params [Nanoc::CLI::Command, nil] command The command that is
    #   currently being executed, or nil if there is none
    def initialize(params = {})
      @command = params[:command]
    end

    # Enables error handling in the given block.
    #
    # @option params [Nanoc::CLI::Command, nil] command The command that is
    #   currently being executed, or nil if there is none
    #
    # @return [void]
    def self.handle_while(params = {}, &block)
      if @disabled
        yield
      else
        new(params).handle_while(&block)
      end
    end

    # Disables error handling. This is used by the test cases to prevent error
    # from being handled by the CLI while tests are running.
    #
    # @api private
    def self.disable
      @disabled = true
    end

    # Re-enables error handling after it was disabled. This is used by the test
    # cases to prevent error from being handled by the CLI while tests are
    # running.
    #
    # @api private
    def self.enable
      @disabled = false
    end

    # Enables error handling in the given block. This method should not be
    # called directly; use {Nanoc::CLI::ErrorHandler.handle_while} instead.
    #
    # @return [void]
    #
    # @api private
    def handle_while(&block)
      # Set exit handler
      %w( INT TERM ).each do |signal|
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
    rescue Nanoc::Errors::GenericTrivial => e
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
    # @api private
    #
    # @return [void]
    def write_compact_error(error, stream)
      # Header
      stream.puts
      stream.puts 'Captain! We’ve been hit!'

      # Sections
      write_error_message(stream, error)
      write_compilation_stack(stream, error)
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
    # @api private
    #
    # @return [void]
    def write_verbose_error(error, stream)
      # Header
      stream.puts "Crashlog created at #{Time.now}"

      # Sections
      write_error_message(stream, error, :verbose => true)
      write_compilation_stack(stream, error, :verbose => true)
      write_stack_trace(stream, error, :verbose => true)
      write_version_information(stream,        :verbose => true)
      write_system_information(stream,        :verbose => true)
      write_installed_gems(stream,        :verbose => true)
      write_environment(stream,        :verbose => true)
      write_gemfile_lock(stream,        :verbose => true)
      write_load_paths(stream,        :verbose => true)
    end

  protected

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @see Nanoc::CLI.debug?
    def debug?
      Nanoc::CLI.debug?
    end

    # @return [Nanoc::Site] The site that is currently being processed
    def site
      @command && @command.site
    end

    # @return [Nanoc::Compiler] The compiler for the current site
    def compiler
      site && site.compiler
    end

    # @return [Array] The current compilation stack
    def stack
      (compiler && compiler.stack) || []
    end

    # @return [Hash<String, Array>] A hash containing the gem names as keys and gem versions as value
    def gems_and_versions
      gems = {}
      Gem::Specification.find_all.sort_by { |s| [ s.name, s.version ] }.each do |spec|
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
      'pry'            => 'pry',
      'rack'           => 'rack',
      'rack/cache'     => 'rack-cache',
      'rainpress'      => 'rainpress',
      'rdiscount'      => 'rdiscount',
      'redcarpet'      => 'redcarpet',
      'redcloth'       => 'RedCloth',
      'rubypants'      => 'rubypants',
      'sass'           => 'sass',
      'w3c_validators' => 'w3c_validators'
    }

    # Attempts to find a resolution for the given error, or nil if no
    # resolution can be automatically obtained.
    #
    # @param [Error] error The error to find a resolution for
    #
    # @return [String] The resolution for the given error
    def resolution_for(error)
      case error
      when LoadError
        # Get gem name
        matches = error.message.match(/(no such file to load|cannot load such file) -- ([^\s]+)/)
        return nil if matches.nil?
        gem_name = GEM_NAMES[matches[2]]

        # Build message
        if gem_name
          if self.using_bundler?
            'Make sure the gem is added to Gemfile and run `bundle install`.'
          else
            "Install the '#{gem_name}' gem using `gem install #{gem_name}`."
          end
        end
      when RuntimeError
        if error.message =~ /^can't modify frozen/
          "You attempted to modify immutable data. Some data, such as " \
          "item/layout attributes and raw item/layout content, can not " \
          "be modified once compilation has started. (This was " \
          "unintentionally possible in 3.1.x and before, but has been " \
          "disabled in 3.2.x in order to allow compiler optimisations.)"
        end
      end
    end

    def using_bundler?
      defined?(Bundler) && Bundler::SharedHelpers.in_bundle?
    end

    def write_section_header(stream, title, params = {})
      stream.puts
      if params[:verbose]
        stream.puts '===== ' + title.upcase + ':'
      else
        stream.puts "\e[1m\e[31m" + title + ':' + "\e[0m"
      end
      stream.puts
    end

    def write_error_message(stream, error, params = {})
      write_section_header(stream, 'Message', params)

      stream.puts "#{error.class}: #{error.message}"
      resolution = resolution_for(error)
      stream.puts "#{resolution}" if resolution
    end

    def write_compilation_stack(stream, error, params = {})
      write_section_header(stream, 'Compilation stack', params)

      if stack.empty?
        stream.puts '  (empty)'
      else
        stack.reverse.each do |obj|
          if obj.is_a?(Nanoc::ItemRep)
            stream.puts "  - [item]   #{obj.item.identifier} (rep #{obj.name})"
          else # layout
            stream.puts "  - [layout] #{obj.identifier}"
          end
        end
      end
    end

    def write_stack_trace(stream, error, params = {})
      is_verbose = params.fetch(:verbose, false)

      write_section_header(stream, 'Stack trace', params)

      count = is_verbose ? -1 : 10
      error.backtrace[0...count].each_with_index do |item, index|
        stream.puts "  #{index}. #{item}"
      end
      if !is_verbose && error.backtrace.size > count
        stream.puts "  ... #{error.backtrace.size - count} more lines omitted. See full crash log for details."
      end
    end

    def write_issue_link(stream, params = {})
      stream.puts
      stream.puts 'If you believe this is a bug in nanoc, please do report it at'
      stream.puts '-> https://github.com/nanoc/nanoc/issues/new <-'
      stream.puts
      stream.puts 'A detailed crash log has been written to ./crash.log.'
    end

    def write_version_information(stream, params = {})
      write_section_header(stream, 'Version information', params)
      stream.puts Nanoc.version_information
    end

    def write_system_information(stream, params = {})
      uname = `uname -a`
      write_section_header(stream, 'System information', params)
      stream.puts uname
    rescue Errno::ENOENT
    end

    def write_installed_gems(stream, params = {})
      write_section_header(stream, 'Installed gems', params)
      gems_and_versions.each do |g|
        stream.puts "  #{g.first} #{g.last.join(', ')}"
      end
    end

    def write_environment(stream, params = {})
      write_section_header(stream, 'Environment', params)
      ENV.sort.each do |e|
        stream.puts "#{e.first} => #{e.last.inspect}"
      end
    end

    def write_gemfile_lock(stream, params = {})
      if File.exist?('Gemfile.lock')
        write_section_header(stream, 'Gemfile.lock', params)
        stream.puts File.read('Gemfile.lock')
      end
    end

    def write_load_paths(stream, params = {})
      write_section_header(stream, 'Load paths', params)
      $LOAD_PATH.each_with_index do |i, index|
        stream.puts "  #{index}. #{i}"
      end
    end

  end

end
