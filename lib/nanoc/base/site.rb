module Nanoc

  # Nanoc::Site is the in-memory representation of a nanoc site directory.
  # 
  # It holds references to the following site data:
  # 
  # * pages
  # * page defaults
  # * layouts
  # * templates
  # * code
  # * configuration (config.yaml file)
  # 
  # Each Nanoc::Site also has a compiler (Nanoc::Compiler) and a data source
  # (Nanoc::DataSource).
  class Site

    DEFAULT_CONFIG = {
      :output_dir   => 'output',
      :data_source  => 'filesystem'
    }

    attr_reader :config
    attr_reader :compiler, :data_source
    attr_reader :code, :pages, :page_defaults, :layouts, :templates

    # Returns a Nanoc::Site object for the site specified by the given
    # configuration hash.
    def initialize(config)
      # Load configuration
      @config = DEFAULT_CONFIG.merge(config.clean)

      # Create data source
      @data_source_class = PluginManager.instance.data_source(@config[:data_source].to_sym)
      error "Unrecognised data source: #{@config[:data_source]}" if @data_source_class.nil?
      @data_source = @data_source_class.new(self)

      # Create compiler
      @compiler     = Compiler.new(self)
      @autocompiler = AutoCompiler.new(self)

      # Set not loaded
      @data_loaded = false
    end

    # Loads the site data. The site data is cached, so calling this method
    # will not have any effect the second time, unless +force+ is true.
    def load_data(force=false)
      return if @data_loaded and !force

      log(:low, "Loading data...")

      # Load data
      @data_source.loading do
        # Code
        @code           = @data_source.code

        # Pages
        @pages          = @data_source.pages
        if @pages.any? { |p| p.is_a? Hash }
          warn "in nanoc 2.1, DataSource#pages should return an array of Page objects"
          @pages.map! { |p| Page.new(p[:uncompiled_content], p, p[:path]) }
        end
        @pages.each { |p| p.site = self }

        # Page defaults
        @page_defaults  = @data_source.page_defaults

        # Layouts
        @layouts        = @data_source.layouts
        if @layouts.any? { |l| l.is_a? Hash }
          warn "in nanoc 2.1, DataSource#layouts should return an array of Layout objects"
          @layouts.map! { |l| Layout.new(l[:content], l, l[:path] || l[:name]) }
        end
        @layouts.each { |l| l.site = self }

        # Templates
        @templates      = @data_source.templates
      end

      # Load code
      eval(@code, TOPLEVEL_BINDING)

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

    # Creates a new site directory on disk. +path+ is the path to the new
    # site directory.
    # 
    # Newly created sites always use the filesystem data source, although it
    # is possible to change the data source after the site is created.
    def self.create(path)
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

    # Compiles the site (calls Nanoc::Compiler#run for the site's compiler)
    # and writes the compiled site to the output directory specified in the
    # site configuration file.
    def compile(path=nil, all=false)
      load_data

      # Find page with given path
      if path.nil?
        page = nil
      else
        page = @pages.find { |page| page.path == "/#{path.gsub(/^\/|\/$/, '')}/" }
        error "The '/#{path.gsub(/^\/|\/$/, '')}/' page was not found; aborting." if page.nil?
      end

      @compiler.run(page, all)
    end

    # Starts the autocompiler (calls Nanoc::AutoCompiler#start) on the
    # specified port number indicated by +port+.
    def autocompile(port)
      @autocompiler.start(port)
    end

    # Sets up the site's data source. This will call Nanoc::DataSource#setup
    # for this site's data source.
    def setup
      @data_source.loading { @data_source.setup }
    end

    # Returns the layout with the given path.
    def layout_with_path(path)
      @layouts.find { |l| l.path == path }
    end

    # Creates a new blank page (calls DataSource#create_page) with the given
    # page path (+path+) and with the given template name (+template_name+).
    def create_page(path, template_name='default')
      load_data

      template = @templates.find { |t| t[:name] == template_name }
      error "A template named '#{template_name}' was not found; aborting." if template.nil?

      @data_source.loading { @data_source.create_page(path, template) }
    end

    # Creates a new blank template (calls DataSource#create_template) with
    # +name+ as the template name.
    def create_template(name)
      load_data

      @data_source.loading {@data_source.create_template(name) }
    end

    # Creates a new blank layout (calls DataSource#create_layout) with
    # +name+ as the layout name.
    def create_layout(name)
      load_data

      @data_source.loading { @data_source.create_layout(name) }
    end

  end

end
