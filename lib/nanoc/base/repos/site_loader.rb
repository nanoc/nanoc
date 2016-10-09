module Nanoc::Int
  class SiteLoader
    def new_empty
      site_from_config(Nanoc::Int::Configuration.new.with_defaults)
    end

    def new_with_config(hash)
      site_from_config(Nanoc::Int::Configuration.new(hash: hash).with_defaults)
    end

    def new_from_cwd
      site_from_config(Nanoc::Int::ConfigLoader.new.new_from_cwd)
    end

    # @return [Boolean]
    def self.cwd_is_nanoc_site?
      Nanoc::Int::ConfigLoader.cwd_is_nanoc_site?
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

      Nanoc::Int::Site.new(
        config: config,
        code_snippets: code_snippets,
        items: items,
        layouts: layouts,
      )
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
