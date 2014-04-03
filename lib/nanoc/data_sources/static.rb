# encoding: utf-8

module Nanoc::DataSources

  # The static data source provides items from a single directory. Unlike the
  # filesystem data sources, static provides no additional item metadata. In
  # addition, all items are treated as 'binary', regardless of their extension
  # or content. As such, it is most useful for simple assets, not for normal
  # content.
  #
  # The identifier for static items is the full item path. For example, if your
  # static data source item_root is `static`, an item named `foo.css` would have
  # the identifier `/static/foo.css/`. Note that, unlike the filesystem data
  # sources, `foo/index.html` and `foo.yaml` receive no special treatment. They
  # are simple static items, just like `foo.css`.
  #
  # The default data source directory is `static/`, but this can be overridden
  # in the data source configuration:
  #
  #     data_sources:
  #       - type:   static
  #         prefix: assets
  #
  # Unless the `hide_items` configuration attribute is false, items from static
  # data sources will have the :is_hidden attribute set by default, which will
  # exclude them from the Blogging helper's atom feed generator, among other
  # things.
  class Static < Nanoc::DataSource

    identifier :static

    def items
      # Get prefix
      prefix = config[:prefix] || 'static'

      # Convert filenames to items
      all_files_in(prefix).map do |filename|
        attributes = {
          :extension => File.extname(filename)[1..-1],
          :filename  => filename,
        }
        attributes[:is_hidden] = true unless config[:hide_items] == false
        identifier = filename[(prefix.length + 1)..-1] + '/'
        mtime      = File.mtime(filename)
        checksum   = Pathname.new(filename).checksum

        Nanoc::Item.new(
          filename,
          attributes,
          identifier,
          :binary => true, :mtime => mtime, :checksum => checksum
        )
      end
    end

  protected

    def all_files_in(dir_name)
      Nanoc::Extra::FilesystemTools.all_files_in(dir_name)
    end

  end

end
