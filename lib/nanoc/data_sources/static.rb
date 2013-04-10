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
  #    data_sources:
  #      - type:   static
  #        prefix: assets
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

      # Get all files under prefix dir
      filenames = []
      entries = Dir[prefix + '/**/*']
      until entries.empty? do
        entry = entries.pop
        filenames << entry if File.file?(entry)
        if File.symlink?(entry) && File.directory?(entry) then
          entries += Dir[entry + '/**/*'] unless File.readlink(entry) == '.' # maybe some more checks like '..'
          raise 'Directory Stack too large' if entries.size > 100000         # TODO proper Error and limit
        end
      end

      # Convert filenames to items
      filenames.map do |filename|
        attributes = {
          :extension => File.extname(filename)[1..-1],
          :filename  => filename,
        }
        attributes[:is_hidden] = true unless config[:hide_items] == false
        identifier = filename[(prefix.length+1)..-1] + '/'

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

  end
end
