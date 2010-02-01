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

    # See {Nanoc3::DataSources::Filesystem#load_objects}.
    def load_objects(dir_name, kind, klass)
      meta_filenames(dir_name).map do |meta_filename|
        # Read metadata
        meta = YAML.load_file(meta_filename) || {}

        # Get content
        content_filename = content_filename_for_dir(File.dirname(meta_filename))
        content = File.read(content_filename)

        # Get attributes
        attributes = {
          :content_filename => content_filename,
          :meta_filename    => meta_filename,
          :extension        => File.extname(content_filename)[1..-1],
          # WARNING :file is deprecated; please create a File object manually
          # using the :content_filename or :meta_filename attributes.
          :file             => Nanoc3::Extra::FileProxy.new(content_filename)
        }.merge(meta)

        # Get identifier
        identifier = meta_filename_to_identifier(meta_filename, Regexp.compile("^#{dir_name}"))

        # Get modification times
        meta_mtime    = File.stat(meta_filename).mtime
        content_mtime = File.stat(content_filename).mtime
        mtime         = meta_mtime > content_mtime ? meta_mtime : content_mtime

        # Create item object
        Nanoc3::Item.new(content, attributes, identifier, mtime)
      end
    end

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

    # Returns the list of all meta files in the given base directory as well
    # as its subdirectories.
    def meta_filenames(base)
      # Find all possible meta file names
      filenames = Dir[base + '/**/*.yaml']

      # Filter out invalid meta files
      good_filenames = []
      bad_filenames  = []
      filenames.each do |filename|
        if filename =~ /meta\.yaml$/ or filename =~ /([^\/]+)\/\1\.yaml$/
          good_filenames << filename
        else
          bad_filenames << filename
        end
      end

      # Warn about bad filenames
      unless bad_filenames.empty?
        raise RuntimeError.new(
          "The following files appear to be meta files, " +
          "but have an invalid name:\n  - " +
          bad_filenames.join("\n  - ")
        )
      end

      good_filenames
    end

    # Returns the filename of the content file in the given directory,
    # ignoring any unwanted files (files that end with '~', '.orig', '.rej' or
    # '.bak')
    def content_filename_for_dir(dir)
      # Find all files
      filename_glob_1 = dir.sub(/([^\/]+)$/, '\1/\1.*')
      filename_glob_2 = dir.sub(/([^\/]+)$/, '\1/index.*')
      filenames = (Dir[filename_glob_1] + Dir[filename_glob_2]).uniq

      # Reject meta files
      filenames.reject! { |f| f =~ /\.yaml$/ }

      # Reject backups
      filenames.reject! { |f| f =~ /(~|\.orig|\.rej|\.bak)$/ }

      # Make sure there is only one content file
      if filenames.size != 1
        raise RuntimeError.new(
          "Expected 1 content file in #{dir} but found #{filenames.size}"
        )
      end

      # Return content filename
      filenames.first
    end

    def meta_filename_to_identifier(meta_filename, regex)
      meta_filename.sub(regex, '').sub(/[^\/]+\.yaml$/, '')
    end

  end

end
