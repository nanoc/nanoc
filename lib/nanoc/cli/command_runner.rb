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
      if self.is_in_site_dir? && @site.nil?
        @site = Nanoc::Site.new('.')
      end

      @site
    end

    # @return [Boolean] true if the current working directory is a nanoc site
    #   directory, false otherwise
    def is_in_site_dir?
      Nanoc::Site.cwd_is_nanoc_site?
    end

    # Asserts that the current working directory contains a site
    # ({Nanoc::Site} instance). If no site is present, prints an error
    # message and exits.
    #
    # @return [void]
    def require_site
      if site.nil?
        raise ::Nanoc::Errors::GenericTrivial, "The current working directory does not seem to be a nanoc site."
      end
    end

    # Asserts that the current working directory contains a site (just like
    # {#require_site}) and loads the site into memory.
    #
    # @return [void]
    def load_site
      self.require_site
      print "Loading site data… "
      self.site.load
      puts "done"
    end

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @see Nanoc::CLI.debug?
    def debug?
      Nanoc::CLI.debug?
    end

    # @return [Array] The compilation stack.
    def stack
      (self.site && self.site.compiler.stack) || []
    end

  end

end
