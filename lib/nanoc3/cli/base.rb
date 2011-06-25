# encoding: utf-8

module Nanoc3::CLI

  class Base

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @since 3.2.0
    attr_accessor :debug
    alias_method :debug?, :debug

    def initialize
      @debug = false
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

  protected

    def stack
      (self.site && self.site.compiler.stack) || []
    end

  end

end
