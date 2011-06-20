# encoding: utf-8

module Nanoc3::CLI

  class Base

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @since 3.2.0
    attr_accessor :debug
    alias_method :debug?, :debug

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
      'fssm'           => 'fssm',
      'haml'           => 'haml',
      'json'           => 'json',
      'kramdown'       => 'kramdown',
      'less'           => 'less',
      'markaby'        => 'markaby',
      'maruku'         => 'maruku',
      'mime/types'     => 'mime-types',
      'nokogiri'       => 'nokogiri',
      'rack'           => 'rack',
      'rack/cache'     => 'rack-cache',
      'rainpress'      => 'rainpress',
      'rdiscount'      => 'rdiscount',
      'redcarpet'      => 'redcarpet',
      'redcloth'       => 'redcloth',
      'rubypants'      => 'rubypants',
      'sass'           => 'sass',
      'systemu'        => 'systemu',
      'w3c_validators' => 'w3c_validators'
    }

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

    # @see Cri::Base#handle_option
    def handle_option(key, value, command)
      case key
      when :version
        gem_info = defined?(Gem) ? "with RubyGems #{Gem::VERSION}" : "without RubyGems"
        engine   = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"

        puts "nanoc #{Nanoc3::VERSION} (c) 2007-2011 Denis Defreyne."
        puts "Running #{engine} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) on #{RUBY_PLATFORM} #{gem_info}"
        exit 0
      when :verbose
        Nanoc3::CLI::Logger.instance.level = :low
      when :debug
        @debug = true
      when :warn
        $-w = true
      when :color
        Nanoc3::CLI::Logger.instance.color = true
      when :'no-color'
        Nanoc3::CLI::Logger.instance.color = false
      when :help
        show_help(command)
        exit 0
      end
    end

  protected

    def stack
      (self.site && self.site.compiler.stack) || []
    end

  end

end
