# encoding: utf-8

module Nanoc::DataSources
  # The filesystem_verbose data source is the old data source for a new nanoc
  # site. It stores all data as files on the hard disk.
  #
  # None of the methods are documented in this file. See {Nanoc::DataSource}
  # for documentation on the overridden methods instead.
  #
  # The filesystem_verbose data source stores its items and layouts in nested
  # directories. Each directory represents a single item or layout. The root
  # directory for items is the `content` directory; for layouts it is the
  # `layouts` directory.
  #
  # Every directory has a content file and a meta file. The content file
  # contains the actual item content, while the meta file contains the item’s
  # or the layout’s metadata, formatted as YAML.
  #
  # Both content files and meta files are named after its parent directory
  # (i.e. item). For example, an item/layout named `foo` will have a directory
  # named `foo`, with e.g. a `foo.markdown` content file and a `foo.yaml` meta
  # file.
  #
  # Content file extensions are not used for determining the filter that
  # should be run; the meta file defines the list of filters. The meta file
  # extension must always be `.yaml`, though.
  #
  # For backwards compatibility, content files can also have the `index`
  # basename. Similarly, meta files can have the `meta` basename. For example,
  # a parent directory named `foo` can have an `index.txt` content file and a
  # `meta.yaml` meta file.
  #
  # The identifier is calculated by stripping the extension; if there is more
  # than one extension, only the last extension is stripped and the previous
  # extensions will be part of the identifier.
  #
  # It is possible to set an explicit encoding that should be used when reading
  # files. In the data source configuration, set `encoding` to an encoding
  # understood by Ruby’s `Encoding`. If no encoding is set in the configuration,
  # one will be inferred from the environment.
  #
  # @api private
  class FilesystemVerbose < Nanoc::DataSource
    include Nanoc::DataSources::Filesystem

    private

    # See {Nanoc::DataSources::Filesystem#filename_for}.
    def filename_for(base_filename, ext)
      return nil if ext.nil?

      last_component = base_filename[%r{[^/]+$}]
      possibilities = [
        base_filename + (ext.empty? ? '' : '.' + ext),                        # foo/bar.html
        base_filename + '/' + last_component + (ext.empty? ? '' : '.' + ext), # foo/bar/bar.html
        base_filename + '/' + 'index' + (ext.empty? ? '' : '.' + ext)         # foo/bar/index.html
      ]

      possibilities.find { |p| File.file?(p) }
    end

    # See {Nanoc::DataSources::Filesystem#identifier_for_filename}.
    def identifier_for_filename(filename)
      if config[:identifier_type] == 'full'
        return Nanoc::Identifier.new(filename, style: :full)
      end

      filename.sub(/[^\/]+\.yaml$/, '')
    end
  end
end
