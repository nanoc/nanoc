# encoding: utf-8

module Nanoc::Filters
  class Sass < Nanoc::Filter

    identifier :sass

    requires 'sass', 'nanoc/filters/sass/sass_filesystem_importer'

    class << self
      # The current filter. This is definitely going to bite me if I ever get
      # to multithreading nanoc.
      attr_accessor :current
    end

    # Runs the content through [Sass](http://sass-lang.com/).
    # Parameters passed to this filter will be passed on to Sass.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Build options
      options = params.dup
      sass_filename = options[:filename] ||
        (@item && @item[:content_filename])
      options[:filename] ||= sass_filename
      options[:filesystem_importer] ||=
        Nanoc::Filters::Sass::SassFilesystemImporter

      # Find items
      item_dirglob = Pathname.new(sass_filename).dirname.realpath.to_s + '**'
      clean_items = @items.reject { |i| i[:content_filename].nil? }
      @scoped_items, @rest_items = clean_items.partition do |i|
        i[:content_filename] &&
          Pathname.new(i[:content_filename]).realpath.fnmatch(item_dirglob)
      end
      
      # Render
      engine = ::Sass::Engine.new(content, options)
      self.class.current = self
      engine.render
    end

    def imported_filename_to_item(filename)
      filematch = lambda do |i|
        i[:content_filename] &&
          Pathname.new(i[:content_filename]).realpath == Pathname.new(filename).realpath
      end
      @scoped_items.find(&filematch) || @rest_items.find(&filematch)
    end

  end
end
