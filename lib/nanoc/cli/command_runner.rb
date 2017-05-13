# frozen_string_literal: true

module Nanoc::CLI
  # A command runner subclass for Nanoc commands that adds Nanoc-specific
  # convenience methods and error handling.
  #
  # @api private
  class CommandRunner < ::Cri::CommandRunner
    # @see http://rubydoc.info/gems/cri/Cri/CommandRunner#call-instance_method
    #
    # @return [void]
    def call
      Nanoc::CLI::ErrorHandler.handle_while(command: self) do
        run
      end
    end

    # Gets the site ({Nanoc::Int::Site} instance) in the current directory and
    # loads its data.
    #
    # @return [Nanoc::Int::Site] The site in the current working directory
    def site
      # Load site if possible
      @site ||= nil
      if is_in_site_dir? && @site.nil?
        @site = Nanoc::Int::SiteLoader.new.new_from_cwd
      end

      @site
    end

    # For debugging purposes.
    #
    # @api private
    def site=(new_site)
      @site = new_site
    end

    # @return [Boolean] true if the current working directory is a Nanoc site
    #   directory, false otherwise
    def in_site_dir?
      Nanoc::Int::SiteLoader.cwd_is_nanoc_site?
    end
    alias is_in_site_dir? in_site_dir?

    # Asserts that the current working directory contains a site and loads the site into memory.
    #
    # @return [void]
    def load_site(preprocess: false)
      $stderr.print 'Loading site… '
      $stderr.flush

      if site.nil?
        raise ::Nanoc::Int::Errors::GenericTrivial, 'The current working directory does not seem to be a Nanoc site.'
      end

      if preprocess
        site.compiler.action_provider.preprocess(site)
      end

      $stderr.puts 'done'
    end

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @see Nanoc::CLI.debug?
    def debug?
      Nanoc::CLI.debug?
    end
  end
end
