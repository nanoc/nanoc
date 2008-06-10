module Nanoc

  # A Nanoc::Site is the in-memory representation of a nanoc site. It holds
  # references to the following site data:
  #
  # * +pages+ is a list of Nanoc::Page instances representing pages
  # * +page_defaults+ is a Nanoc::PageDefaults instance representing page
  #   defaults
  # * +layouts+ is a list of Nanoc::Layout instances representing layouts
  # * +templates+ is a list of Nanoc::Template representing templates
  # * +code+ is a Nanoc::Code instance representing custom site code
  #
  # In addition, each site has a +config+ hash which stores the site
  # configuration. This configuration hash can have the following keys:
  #
  # +output_dir+:: The directory to which compiled pages will be written. This
  #                path is relative to the current working directory, but can
  #                also be an absolute path.
  #
  # +data_source+:: The identifier of the data source that will be used for
  #                 loading site data.
  #
  # +router+:: The identifier of the router that will be used for determining
  #            page paths.
  #
  # +index_filenames+:: A list of filenames that will be stripped off full
  #                     page paths to create cleaner URLs (for example,
  #                     '/about/' will be used instead of
  #                     '/about/index.html'). The default value should be okay
  #                     in most cases.
  #
  # A site also has several helper classes:
  #
  # * +router+ is a Nanoc::Router subclass instance used for determining page
  #   paths.
  # * +data_source+ is a Nanoc::DataSource subclass instance used for managing
  #   site data.
  # * +compiler+ is a Nanoc::Compiler instance that turns pages into compiled
  #   pages.
  #
  # The physical representation of a Nanoc::Site is usually a directory that
  # contains a configuration file, site data, and some rake tasks. However,
  # different frontends may store data differently. For example, a web-based
  # frontend would probably store the configuration and the site content in a
  # database, and would not have rake tasks at all.
  class Site

    # The default configuration for a site. A site's configuration overrides
    # these options: when a Nanoc::Site is created with a configuration that
    # lacks some options, the default value will be taken from
    # +DEFAULT_CONFIG+.
    DEFAULT_CONFIG = {
      :output_dir       => 'output',
      :data_source      => 'filesystem',
      :router           => 'default',
      :index_filenames  => [ 'index.html' ]
    }

    attr_reader :config
    attr_reader :compiler, :data_source, :router
    attr_reader :pages, :page_defaults, :layouts, :templates, :code

    # Returns a Nanoc::Site object for the site specified by the given
    # configuration hash +config+.
    #
    # +config+:: A hash containing the site configuration.
    def initialize(config)
      # Load configuration
      @config = DEFAULT_CONFIG.merge(config.clean)

      # Create data source
      @data_source_class = PluginManager.instance.data_source(@config[:data_source].to_sym)
      raise Nanoc::Errors::UnknownDataSourceError.new(@config[:data_source]) if @data_source_class.nil?
      @data_source = @data_source_class.new(self)

      # Create compiler
      @compiler = Compiler.new(self)

      # Load code (necessary for custom routers)
      load_code

      # Create router
      @router_class = PluginManager.instance.router(@config[:router].to_sym)
      raise Nanoc::Errors::UnknownRouterError.new(@config[:router]) if @router_class.nil?
      @router = @router_class.new(self)

      # Initialize data
      @page_defaults      = PageDefaults.new({})
      @page_defaults.site = self
      @pages              = []
      @layouts            = []
      @templates          = []
    end

    # Loads the site data. This will query the Nanoc::DataSource associated
    # with the site and fetch all site data. The site data is cached, so
    # calling this method will not have any effect the second time, unless
    # +force+ is true.
    #
    # +force+:: If true, will force load the site data even if it has been
    #           loaded before, to circumvent caching issues.
    def load_data(force=false)
      # Don't load data twice
      @data_loaded ||= false
      return if @data_loaded and !force

      # Load code
      load_code(force)

      # Load pieces
      load_page_defaults
      load_pages
      load_layouts
      load_templates

      # Setup child-parent links
      @pages.each do |page|
        # Get parent
        parent_path = page.path.sub(/[^\/]+\/$/, '')
        parent = @pages.find { |p| p.path == parent_path }
        next if parent.nil? or page.path == '/'

        # Link
        page.parent = parent
        parent.children << page
      end

      # Set loaded
      @data_loaded = true
    end

  private

    def load_code(force=false)
      # Don't load code twice
      @code_loaded ||= false
      return if @code_loaded and !force

      @data_source.loading do
        # Get code
        @code = @data_source.code

        # Fix code if outdated
        if @code.is_a? String
          warn_data_source('Code', 'code', false)
          @code = Code.new(code)
        end

        # Set site
        @code.site = self

        # Execute code
        # FIXME move responsibility for loading site code elsewhere
        @code.load
      end

      # Set loaded
      @code_loaded = true
    end

    # TODO document
    def load_page_defaults
      @data_source.loading do
        # Get page defaults
        @page_defaults = @data_source.page_defaults

        # Fix page defaults if outdated
        if @page_defaults.is_a? Hash
          warn_data_source('PageDefaults', 'page_defaults', false)
          @page_defaults = PageDefaults.new(@page_defaults)
        end

        # Set site
        @page_defaults.site = self
      end
    end

    # TODO document
    def load_pages
      @data_source.loading do
        # Get pages
        @pages = @data_source.pages

        # Fix pages if outdated
        if @pages.any? { |p| p.is_a? Hash }
          warn_data_source('Page', 'pages', true)
          @pages.map! { |p| Page.new(p[:uncompiled_content], p, p[:path]) }
        end

        # Set site
        @pages.each { |p| p.site = self }
      end
    end

    # TODO document
    def load_layouts
      @data_source.loading do
        # Get layouts
        @layouts = @data_source.layouts

        # Fix layouts if outdated
        if @layouts.any? { |l| l.is_a? Hash }
          warn_data_source('Layout', 'layouts', true)
          @layouts.map! { |l| Layout.new(l[:content], l, l[:path] || l[:name]) }
        end

        # Set site
        @layouts.each { |l| l.site = self }
      end
    end

    # TODO document
    def load_templates
      @data_source.loading do
        # Get templates
        @templates = @data_source.templates
        
        # Fix templates if outdated
        if @templates.any? { |t| t.is_a? Hash }
          warn_data_source('Template', 'templates', true)
          @templates.map! { |t| Template.new(t[:content], t[:meta].is_a?(String) ? YAML.load(t[:meta]) : t[:meta], t[:name]) }
        end

        # Set site
        @templates.each { |t| t.site = self }
      end

    end

    def warn_data_source(class_name, method_name, is_array)
      warn(
        "In nanoc 2.1, DataSource##{method_name} should return #{is_array ? 'an array of' : 'a' } Nanoc::#{class_name} object#{is_array ? 's' : ''}. Future versions will not support these outdated data sources.",
        'DEPRECATION WARNING'
      )
    end

  end

end
