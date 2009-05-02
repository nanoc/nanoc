module Nanoc3

  # A Nanoc3::Site is the in-memory representation of a nanoc site. It holds
  # references to the following site data:
  #
  # * +items+ is a list of Nanoc3::Item instances representing items
  # * +layouts+ is a list of Nanoc3::Layout instances representing layouts
  # * +code+ is a Nanoc3::Code instance representing custom site code
  #
  # In addition, each site has a +config+ hash which stores the site
  # configuration. This configuration hash can have the following keys:
  #
  # +output_dir+:: The directory to which compiled items will be written. This
  #                path is relative to the current working directory, but can
  #                also be an absolute path.
  #
  # +data_source+:: The identifier of the data source that will be used for
  #                 loading site data.
  #
  # +router+:: The identifier of the router that will be used for determining
  #            item representation paths.
  #
  # +index_filenames+:: A list of filenames that will be stripped off full
  #                     item paths to create cleaner URLs (for example,
  #                     '/about/' will be used instead of
  #                     '/about/index.html'). The default value should be okay
  #                     in most cases.
  #
  # A site also has several helper classes:
  #
  # * +router+ is a Nanoc3::Router subclass instance used for determining item
  #   paths.
  # * +data_source+ is a Nanoc3::DataSource subclass instance used for loading
  #   site data.
  # * +compiler+ is a Nanoc3::Compiler instance that compiles item
  #   representations.
  #
  # The physical representation of a Nanoc3::Site is usually a directory that
  # contains a configuration file, site data, and some rake tasks. However,
  # different frontends may store data differently. For example, a web-based
  # frontend would probably store the configuration and the site content in a
  # database, and would not have rake tasks at all.
  class Site

    # The default configuration for a site. A site's configuration overrides
    # these options: when a Nanoc3::Site is created with a configuration that
    # lacks some options, the default value will be taken from
    # +DEFAULT_CONFIG+.
    DEFAULT_CONFIG = {
      :output_dir       => 'output',
      :data_source      => 'filesystem',
      :router           => 'default',
      :index_filenames  => [ 'index.html' ]
    }

    attr_reader :config

    # Returns a Nanoc3::Site object for the site specified by the given
    # configuration hash +config+.
    #
    # +config+:: A hash containing the site configuration.
    def initialize(config)
      @config = DEFAULT_CONFIG.merge(config.symbolize_keys)
    end

    # Returns the compiler for this site. Will create a new compiler if none
    # exists yet.
    def compiler
      @compiler ||= Compiler.new(self)
    end

    # Returns the data source for this site. Will create a new data source if
    # none exists yet. Raises Nanoc3::Errors::UnknownDataSourceError if the
    # site configuration specifies an unknown data source.
    def data_source
      return @data_source if @data_source

      data_source_class = Nanoc3::DataSource.named(@config[:data_source])
      raise Nanoc3::Errors::UnknownDataSourceError.new(@config[:data_source]) if data_source_class.nil?
      @data_source = data_source_class.new(self)
    end

    # Returns the router for this site. Will create a new router if none
    # exists yet. Raises Nanoc3::Errors::UnknownRouterError if the site
    # configuration specifies an unknown router.
    def router
      return @router if @router

      router_class = Nanoc3::Router.named(@config[:router])
      raise Nanoc3::Errors::UnknownRouterError.new(@config[:router]) if router_class.nil?
      @router ||= router_class.new(self)
    end

    # Loads the site data. This will query the Nanoc3::DataSource associated
    # with the site and fetch all site data. The site data is cached, so
    # calling this method will not have any effect the second time, unless
    # +force+ is true.
    #
    # +force+:: If true, will force load the site data even if it has been
    #           loaded before, to circumvent caching issues.
    def load_data(force=false)
      # Don't load data twice
      return if @data_loaded and !force

      # Load all data
      data_source.loading do
        load_code(force)
        load_items
        load_layouts
      end

      # Done
      @data_loaded = true
    end

    # Returns this site's code. Raises an exception if data hasn't been loaded yet.
    def code
      raise Nanoc3::Errors::DataNotYetAvailableError.new('Code', false) unless @data_loaded
      @code
    end

    # Returns this site's items. Raises an exception if data hasn't been loaded yet.
    def items
      raise Nanoc3::Errors::DataNotYetAvailableError.new('Items', true) unless @data_loaded
      @items
    end

    # Returns this site's layouts. Raises an exception if data hasn't been loaded yet.
    def layouts
      raise Nanoc3::Errors::DataNotYetAvailableError.new('Layouts', true) unless @data_loaded
      @layouts
    end

  private

    # Loads this site's code and executes it.
    def load_code(force=false)
      # Don't load code twice
      @code_loaded ||= false
      return if @code_loaded and !force

      # Get code
      @code = data_source.code
      @code.site = self

      # Execute code
      @code.load
      @code_loaded = true
    end

    # Loads this site's items, sets up item child-parent relationships and
    # builds each item's list of item representations.
    def load_items
      @items = data_source.items
      @items.each { |p| p.site = self }

      # Setup child-parent links
      @items.each do |item|
        # Get parent
        parent_identifier = item.identifier.sub(/[^\/]+\/$/, '')
        parent = @items.find { |p| p.identifier == parent_identifier }
        next if parent.nil? or item.identifier == '/'

        # Link
        item.parent = parent
        parent.children << item
      end
    end

    # Loads this site's layouts.
    def load_layouts
      @layouts = data_source.layouts
      @layouts.each { |l| l.site = self }
    end

  end

end
