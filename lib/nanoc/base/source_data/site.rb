module Nanoc::Int
  # @api private
  class Site
    # @param [Nanoc::Int::Configuration] config
    def initialize(config)
      @config = config
    end

    # Compiles the site.
    #
    # @return [void]
    #
    # @since 3.2.0
    def compile
      compiler.run
    end

    # Returns the compiler for this site. Will create a new compiler if none
    # exists yet.
    #
    # @return [Nanoc::Int::Compiler] The compiler for this site
    def compiler
      @compiler ||= Nanoc::Int::Compiler.new(self)
    end

    # Returns the data sources for this site. Will create a new data source if
    # none exists yet.
    #
    # @return [Array<Nanoc::DataSource>] The list of data sources for this
    #   site
    #
    # @raise [Nanoc::Int::Errors::UnknownDataSource] if the site configuration
    #   specifies an unknown data source
    def data_sources
      load_code_snippets

      @data_sources ||= begin
        @config[:data_sources].map do |data_source_hash|
          # Get data source class
          data_source_class = Nanoc::DataSource.named(data_source_hash[:type])
          raise Nanoc::Int::Errors::UnknownDataSource.new(data_source_hash[:type]) if data_source_class.nil?

          # Create data source
          data_source_class.new(
            self,
            data_source_hash[:items_root],
            data_source_hash[:layouts_root],
            data_source_hash.merge(data_source_hash[:config] || {}),
          )
        end
      end
    end

    # Returns this site’s code snippets.
    #
    # @return [Array<Nanoc::Int::CodeSnippet>] The list of code snippets in this
    #   site
    def code_snippets
      load
      @code_snippets
    end

    # Returns this site’s items.
    #
    # @return [Array<Nanoc::Int::Item>] The list of items in this site
    def items
      load
      @items
    end

    # Returns this site’s layouts.
    #
    # @return [Array<Nanoc::Int::Layouts>] The list of layout in this site
    def layouts
      load
      @layouts
    end

    # @return [Nanoc::Int::Configuration]
    def config
      @config
    end

    # Fills each item's parent reference and children array with the
    # appropriate items. It is probably not necessary to call this method
    # manually; it will be called when appropriate.
    #
    # @return [void]
    def setup_child_parent_links
      teardown_child_parent_links

      item_map = {}
      @items.each do |item|
        next if item.identifier !~ /\/\z/
        item_map[item.identifier.to_s] = item
      end

      @items.each do |item|
        parent_id_end = item.identifier.to_s.rindex('/', -2)
        next unless parent_id_end

        parent_id = item.identifier.to_s[0..parent_id_end]
        parent = item_map[parent_id]
        next unless parent

        item.parent = parent
        parent.children << item
      end
    end

    # Removes all child-parent links.
    #
    # @api private
    #
    # @return [void]
    def teardown_child_parent_links
      @items.each do |item|
        item.parent = nil
        item.children = []
      end
    end

    # Prevents all further modifications to itself, its items, its layouts etc.
    #
    # @return [void]
    def freeze
      config.__nanoc_freeze_recursively
      items.each(&:freeze)
      layouts.each(&:freeze)
      code_snippets.each(&:freeze)
    end

    # Loads the site data. It is not necessary to call this method explicitly;
    # it will be called when it is necessary.
    #
    # @api private
    #
    # @return [void]
    def load
      return if @loaded || @loading
      @loading = true

      # Load all data
      load_code_snippets
      with_datasources do
        load_items
        load_layouts
      end
      setup_child_parent_links

      # Ensure unique
      ensure_identifier_uniqueness(@items, 'item')
      ensure_identifier_uniqueness(@layouts, 'layout')

      # Load compiler too
      # FIXME: this should not be necessary
      compiler.load

      @loaded = true
    rescue => e
      unload
      raise e
    ensure
      @loading = false
    end

    # Undoes the effects of {#load}. Used when {#load} raises an exception.
    #
    # @api private
    def unload
      return if @unloading
      @unloading = true

      @items_loaded = false
      @items = []
      @layouts_loaded = false
      @layouts = []
      @code_snippets_loaded = false
      @code_snippets = []

      compiler.unload

      @loaded = false
      @unloading = false
    end

    private

    # Executes the given block, making sure that the datasources are
    # available for the duration of the block
    def with_datasources(&_block)
      data_sources.each(&:use)
      yield
    ensure
      data_sources.each(&:unuse)
    end

    # Loads this site’s code and executes it.
    def load_code_snippets
      @code_snippets_loaded ||= false
      return if @code_snippets_loaded
      @code_snippets_loaded = true

      # Get code snippets
      @code_snippets = []
      config[:lib_dirs].each do |lib|
        code_snippets = Dir["#{lib}/**/*.rb"].sort.map do |filename|
          Nanoc::Int::CodeSnippet.new(
            File.read(filename),
            filename,
          )
        end
        @code_snippets.concat(code_snippets)
      end

      # Execute code snippets
      @code_snippets.each(&:load)
    end

    # Loads this site’s items, sets up item child-parent relationships and
    # builds each item's list of item representations.
    def load_items
      @items_loaded ||= false
      return if @items_loaded
      @items_loaded = true

      # Get items
      @items = Nanoc::Int::IdentifiableCollection.new(@config)
      data_sources.each do |ds|
        items_in_ds = ds.items
        items_in_ds.each do |i|
          i.identifier = i.identifier.prefix(ds.items_root)
        end
        @items.concat(items_in_ds)
      end
    end

    # Loads this site’s layouts.
    def load_layouts
      @layouts_loaded ||= false
      return if @layouts_loaded
      @layouts_loaded = true

      # Get layouts
      @layouts = Nanoc::Int::IdentifiableCollection.new(@config)
      data_sources.each do |ds|
        layouts_in_ds = ds.layouts
        layouts_in_ds.each do |l|
          l.identifier = l.identifier.prefix(ds.layouts_root)
        end
        @layouts.concat(layouts_in_ds)
      end
    end

    def ensure_identifier_uniqueness(objects, type)
      seen = Set.new
      objects.each do |obj|
        if seen.include?(obj.identifier)
          raise Nanoc::Int::Errors::DuplicateIdentifier.new(obj.identifier, type)
        end
        seen << obj.identifier
      end
    end
  end
end
