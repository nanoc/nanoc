# frozen_string_literal: true

module Nanoc::Filters
  Nanoc::Filter.define(:sass) do |content, params = {}|
    include Sass
    css(self, @item_rep, content, params)
  end

  Nanoc::Filter.define(:sass_sourcemap) do |content, params = {}|
    include Sass
    sourcemap(self, @item_rep, content, params)
  end

  require 'sass'

  module Sass
    def css(filter, rep, content, params)
      css, = render(filter, rep, content, params)
      css
    end

    def sourcemap(filter, rep, content, params)
      _, sourcemap = render(filter, rep, content, params)
      sourcemap
    end

    private

    def render(filter, rep, content, params = {})
      importer = NanocSassImporter.new(filter)

      options = params.merge(
        load_paths: [importer, *params[:load_paths]&.reject { |p| p.is_a?(String) && %r{^content/} =~ p }],
        importer: importer,
        filename: rep.item.identifier.to_s,
        cache: false,
      )
      sourcemap_path = options.delete(:sourcemap_path)

      engine = ::Sass::Engine.new(content, options)
      css, sourcemap = sourcemap_path ? engine.render_with_sourcemap(sourcemap_path) : engine.render
      [css, sourcemap&.to_json(css_uri: rep.path, type: rep.path.nil? ? :inline : :auto)]
    end

    # @api private
    class NanocSassImporter < ::Sass::Importers::Filesystem
      attr_reader :filter

      def initialize(filter)
        @filter = filter
        super('.')
      end

      def find_relative(name, base_identifier, options)
        base_raw_filename = filter.items[base_identifier].raw_filename

        # we can't resolve a relative filename from an in-memory item
        return unless base_raw_filename

        raw_filename, syntax = ::Sass::Util.destructure(find_real_file(File.dirname(base_raw_filename), name, options))
        return unless raw_filename

        item = raw_filename_to_item(raw_filename)
        # it doesn't make sense to import a file, from Nanoc's content if the corresponding item has been deleted
        raise "unable to map #{raw_filename} to any item" if item.nil?

        filter.depend_on([item])

        options[:syntax] = syntax
        options[:filename] = item.identifier.to_s
        options[:importer] = self
        ::Sass::Engine.new(item.raw_content, options)
      end

      def find(identifier, options)
        items = filter.items.find_all(identifier)
        return if items.empty?

        content = if items.size == 1
                    items.first.compiled_content
                  else
                    items.map { |item| %(@import "#{item.identifier}";) }.join("\n")
                  end

        options[:syntax] = :scss
        options[:filename] = identifier.to_s
        options[:importer] = self
        ::Sass::Engine.new(content, options)
      end

      def key(identifier, _options)
        [self.class.name + ':' + root, identifier.to_s]
      end

      def public_url(identifier, _sourcemap_directory)
        path = filter.items[identifier].path
        return path unless path.nil?

        raw_filename = filter.items[identifier].raw_filename
        return if raw_filename.nil?

        ::Sass::Util.file_uri_from_path(raw_filename)
      end

      def to_s
        'Nanoc Sass Importer'
      end

      def self.raw_filename_to_item_map_for_config(config, items)
        @raw_filename_to_item_map ||= {}
        @raw_filename_to_item_map[config.object_id] ||=
          {}.tap do |map|
            items.each do |item|
              if item.raw_filename
                path = Pathname.new(item.raw_filename).realpath.to_s
                map[path] = item
              end
            end
          end
      end

      def raw_filename_to_item(filename)
        realpath = Pathname.new(filename).realpath.to_s

        map = self.class.raw_filename_to_item_map_for_config(filter.config, filter.items)
        map[realpath]
      end
    end
  end

  module ::Sass::Script::Functions
    def nanoc(string, params)
      assert_type string, :String
      assert_type params, :Hash
      result = options[:importer].filter.instance_eval(string.value)
      case result
      when TrueClass, FalseClass
        bool(result)
      when Array
        list(result, :comma)
      when Hash
        map(result)
      when nil
        null
      when Numeric
        number(result)
      else
        params['unquote'] ? unquoted_string(result) : quoted_string(result)
      end
    end
    declare :nanoc, [:string], var_kwargs: true
  end
end
