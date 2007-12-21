module Nanoc
  class Site

    DEFAULT_CONFIG = {
      :output_dir   => 'output',
      :eruby_engine => 'erb',
      :data_source  => 'filesystem'
    }

    attr_reader :config
    attr_reader :compiler, :data_source
    attr_reader :code, :pages, :page_defaults, :layouts, :templates

    # Creating a Site object

    def self.from_cwd
      File.file?('config.yaml') ? new : nil
    end

    def initialize
      # Load configuration
      @config = DEFAULT_CONFIG.merge((YAML.load_file('config.yaml') || {}).clean)

      # Create data source
      @data_source_class = PluginManager.data_source_named(@config[:data_source])
      error "Unrecognised data source: #{@config[:data_source]}" if @data_source_class.nil?
      @data_source = @data_source_class.new(self)

      # Create compiler
      @compiler     = Compiler.new(self)
      @autocompiler = AutoCompiler.new(self)

      # Set not loaded
      @data_loaded = false
    end

    def load_data(params={})
      return if @data_loaded and params[:force] != true

      # Load data
      @data_source.loading do
        @code           = @data_source.code
        @pages          = @data_source.pages.map { |p| Page.new(p, self) }
        @page_defaults  = @data_source.page_defaults
        @layouts        = @data_source.layouts
        @templates      = @data_source.templates
      end

      # Setup child-parent links
      @pages.each do |page|
        # Skip pages without parent
        next if page.path == '/'

        # Get parent
        parent_path = page.path.sub(/[^\/]+\/$/, '')
        parent = @pages.find { |p| p.path == parent_path }

        # Link
        page.parent = parent
        parent.children << page
      end

      # Set loaded
      @data_loaded = true
    end

    # Compiling

    def compile
      @compiler.run
    end

    def autocompile(port)
      @autocompiler.start(port)
    end

    # Creating

    def setup
      @data_source.loading { @data_source.setup }
    end

    def create_page(name, template_name='default')
      load_data

      template = @templates.find { |t| t[:name] == template_name }

      @data_source.loading { @data_source.create_page(name, template) }
    end

    def create_template(name)
      load_data

      @data_source.loading {@data_source.create_template(name) }
    end

    def create_layout(name)
      load_data

      @data_source.loading { @data_source.create_layout(name) }
    end

  end
end
