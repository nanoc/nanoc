# encoding: utf-8

module Nanoc::Filters
  class Sass

    # Essentially the `Sass::Importers::Filesystem` but registering each
    # import file path.
    class SassFilesystemImporter < ::Sass::Importers::Filesystem

      private

      def _find(dir, name, options)
        full_filename, syntax = ::Sass::Util.destructure(find_real_file(dir, name, options))
        return unless full_filename && File.readable?(full_filename)

        filter = options[:nanoc_current_filter]
        item = filter.imported_filename_to_item(full_filename)
        filter.depend_on([ item ]) unless item.nil?

        options[:syntax] = syntax
        options[:filename] = full_filename
        options[:importer] = self
        ::Sass::Engine.new(File.read(full_filename), options)
      end
    end

  end
end
