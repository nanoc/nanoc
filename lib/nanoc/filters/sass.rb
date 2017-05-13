# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Sass < Nanoc::Filter
    identifier :sass

    requires 'sass', 'nanoc/filters/sass/sass_filesystem_importer'

    # Runs the content through [Sass](http://sass-lang.com/).
    # Parameters passed to this filter will be passed on to Sass.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      options = params.merge(
        nanoc_current_filter: self,
        filename: @item && @item.raw_filename,
      )
      engine = ::Sass::Engine.new(content, options)
      engine.render
    end

    def self.item_filename_map_for_config(config, items)
      @item_filename_map ||= {}
      @item_filename_map[config] ||=
        {}.tap do |map|
          items.each do |item|
            if item.raw_filename
              path = Pathname.new(item.raw_filename).realpath.to_s
              map[path] = item
            end
          end
        end
    end

    def imported_filename_to_item(filename)
      realpath = Pathname.new(filename).realpath.to_s

      map = self.class.item_filename_map_for_config(@config, @items)
      map[realpath]
    end
  end
end
