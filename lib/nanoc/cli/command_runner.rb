# encoding: utf-8

module Nanoc::CLI

  # A command runner subclass for nanoc commands that adds nanoc-specific
  # convenience methods and error handling.
  class CommandRunner < ::Cri::CommandRunner

    # @see http://rubydoc.info/gems/cri/Cri/CommandRunner#call-instance_method
    #
    # @return [void]
    def call
      Nanoc::CLI::ErrorHandler.handle_while(:command => self) do
        self.run
      end
    end

    # Gets the site ({Nanoc::Site} instance) in the current directory and
    # loads its data.
    #
    # @return [Nanoc::Site] The site in the current working directory
    def site
      # Load site if possible
      @site ||= nil
      if File.file?('config.yaml') && @site.nil?
        @site = Nanoc::Site.new('.')
      end

      @site
    end

    # @deprecated use `Cri::CommandDSL#runner`
    #
    # @see http://rubydoc.info/gems/cri/Cri/CommandDSL#runner-instance_method
    def self.call(opts, args, cmd)
      self.new(opts, args, cmd).call
    end

  protected

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @see Nanoc::CLI.debug?
    def debug?
      Nanoc::CLI.debug?
    end

    # Asserts that the current working directory contains a site
    # ({Nanoc::Site} instance). If no site is present, prints an error
    # message and exits.
    #
    # @return [void]
    def require_site
      print "Loading site data... "
      if site.nil?
        puts
        raise ::Nanoc::Errors::GenericTrivial, "The current working directory does not seem to be a nanoc site."
      else
        puts "done"
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
      vcs_class = Nanoc::Extra::VCS.named(vcs_name.to_sym)
      if vcs_class.nil?
        raise Nanoc::Errors::GenericTrivial, "A VCS named #{vcs_name} was not found"
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

  # @deprecated Use {Nanoc::CLI::CommandRunner} instead
  Command = CommandRunner

end
