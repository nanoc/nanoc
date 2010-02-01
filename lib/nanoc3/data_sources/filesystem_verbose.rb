# encoding: utf-8

module Nanoc3::DataSources

  # The filesystem_verbose data source is the old data source for a new nanoc
  # site. It stores all data as files on the hard disk.
  #
  # None of the methods are documented in this file. See {Nanoc3::DataSource}
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
  class FilesystemVerbose < Nanoc3::DataSource

    include Nanoc3::DataSources::Filesystem

  private

    # See {Nanoc3::DataSources::Filesystem#create_object}.
    def create_object(dir_name, content, attributes, identifier)
      # Determine base path
      last_component = identifier.split('/')[-1] || dir_name
      base_path = dir_name + identifier + last_component

      # Get filenames
      dir_path         = dir_name + identifier
      meta_filename    = dir_name + identifier + last_component + '.yaml'
      content_filename = dir_name + identifier + last_component + '.html'
                                     
      # Notify
      Nanoc3::NotificationCenter.post(:file_created, meta_filename)
      Nanoc3::NotificationCenter.post(:file_created, content_filename)

      # Create files
      FileUtils.mkdir_p(dir_path)
      File.open(meta_filename,    'w') { |io| io.write(YAML.dump(attributes.stringify_keys)) }
      File.open(content_filename, 'w') { |io| io.write(content) }
    end

    # See {Nanoc3::DataSources::Filesystem#load_objects}.
    def load_objects(dir_name, kind, klass)
      all_split_files_in(dir_name).map do |base_filename, (meta_ext, content_ext)|
        # Get filenames
        last_part = base_filename.split('/')[-1]
        base_glob = base_filename.split('/')[0..-2].join('/') + "/{index,#{last_part}}."
        meta_filename    = meta_ext    ? Dir[base_glob + meta_ext   ][0] : nil
        content_filename = content_ext ? Dir[base_glob + content_ext][0] : nil

        # Get meta and content
        meta    = (meta_filename    ? YAML.load_file(meta_filename) : nil) || {}
        content = (content_filename ? File.read(content_filename)   : nil) || ''

        # Get attributes
        attributes = {
          :content_filename => content_filename,
          :meta_filename    => meta_filename,
          :extension        => content_filename ? ext_of(content_filename)[1..-1] : nil,
          # WARNING :file is deprecated; please create a File object manually
          # using the :content_filename or :meta_filename attributes.
          :file             => content_filename ? Nanoc3::Extra::FileProxy.new(content_filename) : nil
        }.merge(meta)

        # Get identifier
        if meta_filename
          identifier = identifier_for_filename(meta_filename[(dir_name.length+1)..-1])
        elsif content_filename
          identifier = identifier_for_filename(content_filename[(dir_name.length+1)..-1])
        else
          raise RuntimeError, "meta_filename and content_filename are both nil"
        end

        # Get modification times
        meta_mtime    = meta_filename    ? File.stat(meta_filename).mtime    : nil
        content_mtime = content_filename ? File.stat(content_filename).mtime : nil
        if meta_mtime && content_mtime
          mtime = meta_mtime > content_mtime ? meta_mtime : content_mtime
        elsif meta_mtime
          mtime = meta_mtime
        elsif content_mtime
          mtime = content_mtime
        else
          raise RuntimeError, "meta_mtime and content_mtime are both nil"
        end

        # Create layout object
        klass.new(content, attributes, identifier, mtime)
      end
    end

    def identifier_for_filename(filename)
      filename.sub(/[^\/]+\.yaml$/, '')
    end

  end

end
