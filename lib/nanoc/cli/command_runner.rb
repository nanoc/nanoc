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
        print "Loading site data… "
        @site = Nanoc::SiteLoader.new.load
        puts "done"
      end

      @site
    end

    # @return [Boolean] true if the current working directory is a nanoc site
    #   directory, false otherwise
    def is_in_site_dir?
      Nanoc::SiteLoader.cwd_is_nanoc_site?
    end

    # TODO do not load the site
    def require_site
      self.site
    end

    # TODO move #site logic in here
    def load_site
      self.site
    end

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @see Nanoc::CLI.debug?
    def debug?
      Nanoc::CLI.debug?
    end

  end

end
