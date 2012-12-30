# encoding: utf-8

module Nanoc3::DataSources

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
  #      - type:         static
  #        config:
  #          prefix:     assets
  #
  # Unless the `hide_items` configuration attribute is false, items from static
  # data sources will have the :is_hidden attribute set by default, which will
  # exclude them from the Blogging helper's atom feed generator, among other
  # things.
  class Static < Nanoc3::DataSource
    identifier :static

    def items
      # Get prefix
      prefix = config[:prefix] || 'static'

      # Get all files under prefix dir
      filenames = Dir[prefix + '/**/*'].select { |f| File.file?(f) }

      # Convert filenames to items
      filenames.map do |filename|
        attributes = {
          :extension => File.extname(filename)[1..-1],
          :filename  => filename,
        }
        attributes[:is_hidden] = true unless config[:hide_items] == false
        identifier = filename[(prefix.length+1)..-1] + '/'

        mtime      = File.mtime(filename)
        checksum   = checksum_for(filename)

        Nanoc3::Item.new(
          filename,
          attributes,
          identifier,
          :binary => true, :mtime => mtime, :checksum => checksum
        )
      end
    end

  private

    # Returns a checksum of the given filenames
    # TODO un-duplicate this somewhere
    def checksum_for(*filenames)
      filenames.flatten.map do |filename|
        digest = Digest::SHA1.new
        File.open(filename, 'r') do |io|
          until io.eof
            data = io.readpartial(2**10)
            digest.update(data)
          end
        end
        digest.hexdigest
      end.join('-')
    end
  end
end