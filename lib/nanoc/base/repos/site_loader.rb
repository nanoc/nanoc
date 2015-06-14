module Nanoc::Int
  class SiteLoader
    def new_empty
      site_from_config(Nanoc::Int::Configuration.new.with_defaults)
    end

    def new_with_config(hash)
      site_from_config(Nanoc::Int::Configuration.new(hash).with_defaults)
    end

    def new_from_cwd
      site_from_config(config_from_cwd)
    end

    # @api private
    def setup_child_parent_links(items)
      items.each do |item|
        item.parent = nil
        item.children = []
      end

      item_map = {}
      items.each do |item|
        next if item.identifier !~ /\/\z/
        item_map[item.identifier.to_s] = item
      end

      items.each do |item|
        parent_id_end = item.identifier.to_s.rindex('/', -2)
        next unless parent_id_end

        parent_id = item.identifier.to_s[0..parent_id_end]
        parent = item_map[parent_id]
        next unless parent

        item.parent = parent
        parent.children << item
      end
    end

    private

    def site_from_config(config)
      code_snippets = code_snippets_from_config(config)
      code_snippets.each(&:load)

      items = Nanoc::Int::IdentifiableCollection.new(config)
      layouts = Nanoc::Int::IdentifiableCollection.new(config)

      with_data_sources(config) do |data_sources|
        data_sources.each do |ds|
          items_in_ds = ds.items
          layouts_in_ds = ds.layouts

          items_in_ds.each { |i| i.identifier = i.identifier.prefix(ds.items_root) }
          layouts_in_ds.each { |l| l.identifier = l.identifier.prefix(ds.layouts_root) }

          items.concat(items_in_ds)
          layouts.concat(layouts_in_ds)
        end
      end

      setup_child_parent_links(items)

      Nanoc::Int::Site.new(
        config: config,
        code_snippets: code_snippets,
        items: items,
        layouts: layouts,
      )
    end

    class NoConfigFileFoundError < ::Nanoc::Error
      def initialize
        super('No configuration file found')
      end
    end

    class NoParentConfigFileFoundError < ::Nanoc::Error
      def initialize(filename)
        super("There is no parent configuration file at #{filename}")
      end
    end

    class CyclicalConfigFileError < ::Nanoc::Error
      def initialize(filename)
        super("The parent configuration file at #{filename} includes one of its descendants")
      end
    end

    # @return [Boolean]
    def self.cwd_is_nanoc_site?
      !config_filename_for_cwd.nil?
    end

    # @return [String]
    def self.config_filename_for_cwd
      filenames = %w( nanoc.yaml config.yaml )
      candidate = filenames.find { |f| File.file?(f) }
      candidate && File.expand_path(candidate)
    end

    def config_from_cwd
      # Determine path
      filename = self.class.config_filename_for_cwd
      raise NoConfigFileFoundError if filename.nil?

      # Read
      apply_parent_config(
        Nanoc::Int::Configuration.new(YAML.load_file(filename)),
        [filename]).with_defaults
    end

    def apply_parent_config(config, processed_paths = Set.new)
      parent_path = config[:parent_config_file]
      return config if parent_path.nil?

      # Get absolute path
      parent_path = File.absolute_path(parent_path, File.dirname(processed_paths.last))
      unless File.file?(parent_path)
        raise NoParentConfigFileFoundError.new(parent_path)
      end

      # Check recursion
      if processed_paths.include?(parent_path)
        raise CyclicalConfigFileError.new(parent_path)
      end

      # Load
      parent_config = Nanoc::Int::Configuration.new(YAML.load_file(parent_path))
      full_parent_config = apply_parent_config(parent_config, processed_paths + [parent_path])
      full_parent_config.merge(config.without(:parent_config_file))
    end

    def with_data_sources(config, &_block)
      data_sources = create_data_sources(config)

      begin
        data_sources.each(&:use)
        yield(data_sources)
      ensure
        data_sources.each(&:unuse)
      end
    end

    def create_data_sources(config)
      config[:data_sources].map do |data_source_hash|
        # Get data source class
        data_source_class = Nanoc::DataSource.named(data_source_hash[:type])
        if data_source_class.nil?
          raise Nanoc::Int::Errors::UnknownDataSource.new(data_source_hash[:type])
        end

        # Create data source
        data_source_class.new(
          config,
          data_source_hash[:items_root],
          data_source_hash[:layouts_root],
          data_source_hash.merge(data_source_hash[:config] || {}),
        )
      end
    end

    def code_snippets_from_config(config)
      config[:lib_dirs].flat_map do |lib|
        Dir["#{lib}/**/*.rb"].sort.map do |filename|
          Nanoc::Int::CodeSnippet.new(
            File.read(filename),
            filename,
          )
        end
      end
    end
  end
end
