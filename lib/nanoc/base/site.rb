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
      :output_dir   => 'output',
      :data_source  => 'filesystem',
      :router       => 'default'
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
      error "Unrecognised data source: #{@config[:data_source]}" if @data_source_class.nil?
      @data_source = @data_source_class.new(self)

      # Create compiler
      @compiler = Compiler.new(self)

      # Create router
      @router_class = PluginManager.instance.router(@config[:router].to_sym)
      error "Unrecognised router: #{@config[:router]}" if @router_class.nil?
      @router = @router_class.new(self)

      # Set not loaded
      @data_loaded = false
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
      return if @data_loaded and !force

      log(:low, "Loading data...")

      # Load data
      @data_source.loading do
        # Code
        @code = @data_source.code
        if @code.is_a? String
          warn "in nanoc 2.1, DataSource#code should return a Code object"
          @code = Code.new(code)
        end
        @code.site = self
        # FIXME move responsibility for loading site code elsewhere, so
        # potentially dangerous code can be put in a sandbox.
        @code.load

        # Pages
        @pages = @data_source.pages
        if @pages.any? { |p| p.is_a? Hash }
          warn "in nanoc 2.1, DataSource#pages should return an array of Page objects"
          @pages.map! { |p| Page.new(p[:uncompiled_content], p, p[:path]) }
        end
        @pages.each { |p| p.site = self }

        # Page defaults
        @page_defaults = @data_source.page_defaults
        if @page_defaults.is_a? Hash
          warn "in nanoc 2.1, DataSource#layouts should return a PageDefaults object"
          @page_defaults = PageDefaults.new(@page_defaults)
        end
        @page_defaults.site = self

        # Layouts
        @layouts = @data_source.layouts
        if @layouts.any? { |l| l.is_a? Hash }
          warn "in nanoc 2.1, DataSource#layouts should return an array of Layout objects"
          @layouts.map! { |l| Layout.new(l[:content], l, l[:path] || l[:name]) }
        end
        @layouts.each { |l| l.site = self }

        # Templates
        @templates = @data_source.templates
        if @templates.any? { |t| t.is_a? Hash }
          warn "in nanoc 2.1, DataSource#templates should return an array of Template objects"
          @templates.map! { |t| Template.new(t[:name], t[:content], YAML.load(t[:meta])) }
        end
        @templates.each { |t| t.site = self }
      end

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

    # Compiles the site (calls Nanoc::Compiler#run for the site's compiler)
    # and writes the compiled site to the output directory specified in the
    # site configuration file.
    #
    # +path+:: The path of the page (and its dependencies) that should be
    #          compiled, or +nil+ if the entire site should be compiled.
    #
    # +include_outdated+:: +false+ if outdated pages should not be recompiled,
    #                      and +true+ if they should.
    def compile(path=nil, include_outdated=false)
      load_data

      # Find page with given path
      if path.nil?
        page = nil
      else
        page = @pages.find { |page| page.web_path == "/#{path.gsub(/^\/|\/$/, '')}/" }
        error "The '/#{path.gsub(/^\/|\/$/, '')}/' page was not found; aborting." if page.nil?
      end

      @compiler.run(page, include_outdated)
    end

    # Sets up the site's data source. This will call Nanoc::DataSource#setup
    # for this site's data source.
    def setup
      @data_source.loading { @data_source.setup }
    end

    #################### OUTDATED ####################

    # TODO outdated; remove me (frontend should implement this)
    def self.create(path) # :nodoc:
      # Check whether site exists
      error "A site at '#{path}' already exists." if File.exist?(path)

      FileUtils.mkdir_p(path)
      in_dir([path]) do
        # Create output
        FileManager.create_dir 'output'

        # Create config
        FileManager.create_file 'config.yaml' do
          "output_dir:  \"output\"\n" +
          "data_source: \"filesystem\"\n"
        end

        # Create rakefile
        FileManager.create_file 'Rakefile' do
          "Dir['tasks/**/*.rake'].sort.each { |rakefile| load rakefile }\n" +
          "\n" +
          "task :default do\n" +
          "  puts 'This is an example rake task.'\n" +
          "end\n"
        end

        # Create tasks
        FileManager.create_file 'tasks/default.rake' do
          "task :example do\n" +
          "  puts 'This is an example rake task in tasks/default.rake.'\n" +
          "end\n"
        end

        # Setup site
        Site.new(YAML.load_file('config.yaml')).setup
      end
    end

    # TODO outdated; remove me (frontend should implement this)
    def create_page(path, template_name='default') # :nodoc:
      load_data

      # Find template
      template = @templates.find { |t| t.name == template_name }
      error "A template named '#{template_name}' was not found; aborting." if template.nil?

      @data_source.loading { @data_source.create_page(path, template) }
    end

    # TODO outdated; remove me (frontend should implement this)
    def create_template(name) # :nodoc:
      @data_source.loading {@data_source.create_template(name) }
    end

    # TODO outdated; remove me (frontend should implement this)
    def create_layout(name) # :nodoc:
      @data_source.loading { @data_source.create_layout(name) }
    end

  end

end
