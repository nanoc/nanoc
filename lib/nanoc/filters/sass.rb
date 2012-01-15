# encoding: utf-8

require 'sass'
require 'set'

module Nanoc::Filters
  class Sass < Nanoc::Filter

    class << self
      # The current filter. This is definitely going to bite me if I ever get
      # to multithreading nanoc.
      attr_accessor :current
    end

    # Essentially the `Sass::Importers::Filesystem` but registering each
    # import file path.
    class SassFilesystemImporter < ::Sass::Importers::Filesystem

    private

      def _find(dir, name, options)
        full_filename, syntax = find_real_file(dir, name)
        return unless full_filename && File.readable?(full_filename)

        filter = Nanoc::Filters::Sass.current
        item = filter.imported_filename_to_item(full_filename)
        filter.depend_on([ item ]) unless item.nil?

        options[:syntax] = syntax
        options[:filename] = full_filename
        options[:importer] = self
        ::Sass::Engine.new(File.read(full_filename), options)
      end
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
