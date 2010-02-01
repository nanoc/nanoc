# encoding: utf-8

module Nanoc3::DataSources

  # Items and layouts are stored as pairs of two files: a content file,
  # containing the actual item/layout content, and a meta file, containing the
  # item/layout's attributes, formatted as YAML. The content file and the
  # corresponding meta file have the same filename but not the same extension;
  # the meta file's extension is `.yaml` and the extension of the content file
  # can be freely chosen.
  #
  # Items are stored in the `content` directory of the nanoc site, while
  # layouts are stored in the `layouts` directory.
  #
  # The identifier of a item or layout is determined as follows. A file with
  # an `index.*` content filename, such as `index.txt`, will have the
  # filesystem path with the 'index.*' part stripped as a identifier. For
  # example:
  #
  #     foo/bar/index.html → /foo/bar/
  #
  # In other cases, the identifier is calculated by stripping the extension.
  # If the `allow_periods_in_identifiers` attribute in the configuration is
  # true, only the last extension will be stripped if the file has multiple
  # extensions; if it is false or unset, all extensions will be stripped.
  # For example:
  #
  #     (allow_periods_in_identifiers set to true)
  #     foo.entry.html → /foo.entry/
  #     
  #     (allow_periods_in_identifiers set to false)
  #     foo.html.erb → /foo/
  #
  # Note that it is possible for two different, separate files to have the
  # same identifier. It is recommended to avoid such situations.
  #
  # For example, this directory structure:
  #
  #     content/
  #       index.html
  #       index.yaml
  #       about.html
  #       about.yaml
  #       journal.html
  #       journal.yaml
  #       journal/
  #         2005.html
  #         2005.yaml
  #         2005/
  #           a-very-old-post.html
  #           a-very-old-post.yaml
  #           another-very-old-post.html
  #           another-very-old-post.yaml
  #           foo.entry.html
  #           foo.entry.yaml
  #       myst/
  #         index.html
  #         index.yaml
  #
  # … corresponds with the following items:
  #
  #     /
  #     /about/
  #     /journal/
  #     /journal/2005/
  #     /journal/2005/a-very-old-post/
  #     /journal/2005/another-very-old-post/
  #     /journal/2005/foo.entry/ OR /journal/2005/foo/
  #     /myst/
  class FilesystemCompact < Nanoc3::DataSource

    include Nanoc3::DataSources::Filesystem

  private

    # See {Nanoc3::DataSources::Filesystem#create_object}.
    def create_object(dir_name, content, attributes, identifier)
      # Check for periods
      if (@config.nil? || !@config[:allow_periods_in_identifiers]) && identifier.include?('.')
        raise RuntimeError,
          "Attempted to create an object in #{dir_name} with identifier #{identifier} containing a period, but allow_periods_in_identifiers is not enabled in the site configuration. (Enabling allow_periods_in_identifiers may cause the site to break, though.)"
      end

      # Get filenames
      base_path = dir_name + (identifier == '/' ? '/index' : identifier[0..-2])
      meta_filename    = base_path + '.yaml'
      content_filename = base_path + '.html'

      # Notify
      Nanoc3::NotificationCenter.post(:file_created, meta_filename)
      Nanoc3::NotificationCenter.post(:file_created, content_filename)

      # Create files
      FileUtils.mkdir_p(File.dirname(meta_filename))
      File.open(meta_filename,    'w') { |io| io.write(YAML.dump(attributes.stringify_keys)) }
      File.open(content_filename, 'w') { |io| io.write(content) }
    end

    # See {Nanoc3::DataSources::Filesystem#load_objects}.
    def load_objects(dir_name, kind, klass)
      all_split_files_in(dir_name).map do |base_filename, (meta_ext, content_ext)|
        # Get filenames
        meta_filename    = meta_ext    ? base_filename + '.' + meta_ext    : nil
        content_filename = content_ext ? base_filename + '.' + content_ext : nil

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

        # Create item/layout object
        klass.new(content, attributes, identifier, mtime)
      end
    end

    # Returns the identifier for the given filename. This method assumes that
    # the base is already stripped.
    #
    # For example:
    #
    #     /foo.yaml           -> /foo/
    #     /foo/index.yaml     -> /foo/
    #     /foo/index.erb      -> /foo/
    #     /foo/foo.yaml       -> /foo/foo/
    #     /foo/bar.html       -> /foo/bar/
    #     /foo/bar.entry.yaml -> /foo/bar.entry/
    def identifier_for_filename(filename)
      return basename_of(filename).sub(/index$/, '').cleaned_identifier

      # Split into components
      components = filename.gsub(%r{(^/|/$)}, '').split('/')
      components[-1].sub!(/\.[a-z0-9]+$/, '')

      if components[-1] == 'index'
        components[0..-2].join('/').cleaned_identifier
      else
        components.join('/').cleaned_identifier
      end
    end

  end

end
