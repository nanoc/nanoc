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
    def run(content, params={})
      # Build options
      options = params.dup
      sass_filename = item.content.filename
      # TODO check whether item.identifier exists
      options[:filename] ||= sass_filename
      options[:filesystem_importer] ||= Nanoc::Filters::Sass::SassFilesystemImporter

      # Find items
      item_dirglob = Pathname.new(sass_filename).dirname.realpath.to_s + '**'
      clean_items = @items.reject { |i| i.content.filename.nil? }
      @scoped_items, @rest_items = clean_items.partition do |i|
        i.content.filename && File.fnmatch(item_dirglob, i.content.filename)
      end
      
      # Render
      options[:nanoc_current_filter] = self
      engine = ::Sass::Engine.new(content, options)
      engine.render
    end

    def imported_filename_to_item(filename)
      filematch = lambda do |i|
        i.content.filename == File.absolute_path(filename)
      end
      @scoped_items.find(&filematch) || @rest_items.find(&filematch)
    end

  end
end
