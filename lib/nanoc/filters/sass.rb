# encoding: utf-8

module Nanoc::Filters
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
      options = params.merge({
        :nanoc_current_filter => self,
        :filename => @item && @item.content.filename,
      })
      engine = ::Sass::Engine.new(content, options)
      engine.render
    end

    def imported_filename_to_item(filename)
      absolute_path = File.absolute_path(filename)
      @items.find { |i| i.content.filename == absolute_path }
    end

  end
end
