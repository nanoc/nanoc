# encoding: utf-8

module Nanoc3::CLI

  # An abstract superclass for commands that can be executed. These are not
  # the same as Cri commands, but are used in conjuction with Cri commands.
  # nanoc commands will be called by Cri commands and will perform the actual
  # execution of the command, as well as perform error handling if necessary.
  class Command

    # @return [Hash] A hash contain the options and their values
    attr_reader :options

    # @return [Array] The list of arguments
    attr_reader :arguments

    # @return [Cri::Command] The Cri command
    attr_reader :command

    # @param [Hash] options A hash contain the options and their values
    #
    # @param [Array] arguments The list of arguments
    #
    # @param [Cri::Command] command The Cri command
    def initialize(options, arguments, command)
      @options   = options
      @arguments = arguments
      @command   = command
    end

    # Runs the command with the given options, arguments and Cri command. This
    # is a convenience method so that no individual command needs to be
    # created.
    #
    # @param [Hash] options A hash contain the options and their values
    #
    # @param [Array] arguments The list of arguments
    #
    # @param [Cri::Command] command The Cri command
    #
    # @return [void]
    def self.call(options, arguments, command)
      self.new(options, arguments, command).call
    end

    # Runs the command.
    #
    # @return [void]
    def call
      Nanoc3::CLI::ErrorHandler.handle_while(:command => self) do
        self.run
      end
    end

    # Performs the actual execution of the command.
    #
    # @return [void]
    #
    # @abstract
    def run
    end

    # Gets the site ({Nanoc3::Site} instance) in the current directory and
    # loads its data.
    #
    # @return [Nanoc3::Site] The site in the current working directory
    def site
      # Load site if possible
      @site ||= nil
      if File.file?('config.yaml') && @site.nil?
        begin
          @site = Nanoc3::Site.new('.')
        rescue Nanoc3::Errors::UnknownDataSource => e
          $stderr.puts "Unknown data source: #{e}"
          exit 1
        end
      end

      @site
    end

  protected

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @see Nanoc3::CLI.debug?
    def debug?
      Nanoc3::CLI.debug?
    end

    # Asserts that the current working directory contains a site
    # ({Nanoc3::Site} instance). If no site is present, prints an error
    # message and exits.
    #
    # @return [void]
    def require_site
      @site = nil
      if site.nil?
        $stderr.puts 'The current working directory does not seem to be a ' +
                     'valid/complete nanoc site directory; aborting.'
        exit 1
      end
    end

    # Sets the data source's VCS to the VCS with the given name. Does nothing
    # when the site's data source does not support VCSes (i.e. does not
    # implement #vcs=).
    #
    # @param [String] vcs_name The name of the VCS that should be used
    #
    # @return [void]
    def set_vcs(vcs_name)
      # Skip if not possible
      return if vcs_name.nil? || site.nil?

      # Find VCS
      vcs_class = Nanoc3::Extra::VCS.named(vcs_name.to_sym)
      if vcs_class.nil?
        $stderr.puts "A VCS named #{vcs_name} was not found; aborting."
        exit 1
      end

      site.data_sources.each do |data_source|
        # Skip if not possible
        next if !data_source.respond_to?(:vcs=)

        # Set VCS
        data_source.vcs = vcs_class.new
      end
    end

    # @return [Array] The compilation stack.
    def stack
      (self.site && self.site.compiler.stack) || []
    end

  end

end
