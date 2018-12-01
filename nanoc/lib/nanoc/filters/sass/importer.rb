# frozen_string_literal: true

module Nanoc::Filters::SassCommon
  # @api private
  class Importer < ::Sass::Importers::Filesystem
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

      content = item ? item.raw_content : File.read(raw_filename)
      filename = item ? item.identifier.to_s : raw_filename

      filter.depend_on([item]) if item

      options[:syntax] = syntax
      options[:filename] = filename
      options[:importer] = self
      ::Sass::Engine.new(content, options)
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
