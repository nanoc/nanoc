# frozen_string_literal: true

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

      data_sources_to_aggregate =
        with_data_sources(config) do |data_sources|
          data_sources.map do |ds|
            Nanoc::Int::PrefixedDataSource.new(ds, ds.items_root, ds.layouts_root)
          end
        end

      data_source = Nanoc::Int::AggregateDataSource.new(data_sources_to_aggregate, config)

      Nanoc::Int::Site.new(
        config: config,
        code_snippets: code_snippets,
        data_source: data_source,
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
        data_source_class = Nanoc::DataSource.named(data_source_hash[:type].to_sym)
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
            read_code_snippet_contents(filename),
            filename,
          )
        end
      end
    end

    ENCODING_REGEX = /\A#\s+(-\*-\s+)?(en)?coding: (?<encoding>[^\s]+)(\s+-\*-\s*)?\n{0,2}/

    def encoding_from_magic_comment(raw)
      match = ENCODING_REGEX.match(raw)
      match ? match['encoding'] : nil
    end

    def read_code_snippet_contents(filename)
      raw = File.read(filename, encoding: 'ASCII-8BIT')

      enc = encoding_from_magic_comment(raw)
      if enc
        raw = raw.force_encoding(enc).encode('UTF-8').sub(ENCODING_REGEX, '')
      else
        raw.force_encoding('UTF-8')
      end

      raw
    end
  end
end
