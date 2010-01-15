# encoding: utf-8

module Nanoc3::DataSources

  # = Items
  #
  # Items are stored as pairs of two files: a content file, containing the
  # actual item content, and a meta file, containing the item's attributes,
  # formatted as YAML. The content file and the corresponding meta file have
  # the same filename but not the same extension; the meta file's extension is
  # .yaml.
  #
  # Items are stored in the "content" directory of the nanoc site.
  #
  # The identifier of a item is determined as follows. A file with an
  # 'index.*' content filename, such as 'index.txt', will have the filesystem
  # path with the 'index.*' part stripped as a identifier. For example:
  #
  #    foo/bar/index.html → /foo/bar/
  #
  # In other cases, the identifier is calculated by stripping the extension.
  # If the `allow_periods_in_identifiers` attribute in the configuration is
  # true, only the last extension will be stripped if the file has multiple
  # extensions; if it is false or unset, all extensions will be stripped.
  # For example:
  #
  #   (allow_periods_in_identifiers set to true)
  #   foo.entry.html → /foo.entry/
  #   
  #   (allow_periods_in_identifiers set to false)
  #   foo.html.erb → /foo/
  #
  # Note that it is possible for two different, separate files to have the
  # same identifier. It is recommended to avoid such situations.
  #
  # For example, this directory structure:
  #
  #   content/
  #     index.html
  #     index.yaml
  #     about.html
  #     about.yaml
  #     journal.html
  #     journal.yaml
  #     journal/
  #       2005.html
  #       2005.yaml
  #       2005/
  #         a-very-old-post.html
  #         a-very-old-post.yaml
  #         another-very-old-post.html
  #         another-very-old-post.yaml
  #         foo.entry.html
  #         foo.entry.yaml
  #     myst/
  #       index.html
  #       index.yaml
  #
  # … corresponds with the following items:
  #
  #   /
  #   /about/
  #   /journal/
  #   /journal/2005/
  #   /journal/2005/a-very-old-post/
  #   /journal/2005/another-very-old-post/
  #   /journal/2005/foo.entry/ OR /journal/2005/foo/
  #   /myst/
  #
  # = Layouts
  #
  # Layouts are stored the same way as items, except that they are stored in
  # the "layouts" directory instead of the "content" directory.
  #
  # The identifier for layouts is generated the same way as identifiers for
  # items (see above for details).
  class FilesystemCompact < Nanoc3::DataSources::Filesystem

  private

    # See superclass for documentation.
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

    # See superclass for documentation.
    def load_objects(dir_name, kind, klass)
      all_files_in(dir_name).map do |base_filename, (meta_ext, content_ext)|
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

        # Create layout object
        klass.new(content, attributes, identifier, mtime)
      end
    end

    # Finds all items/layouts/... in the given base directory. Returns a hash
    # in which the keys are the file's dirname + basenames, and the values a
    # pair consisting of the metafile extension and the content file
    # extension. The meta file extension or the content file extension can be
    # nil, but not both. Backup files are ignored. For example:
    #
    #   {
    #     'content/foo' => [ 'yaml', 'html' ],
    #     'content/bar' => [ 'yaml', nil    ],
    #     'content/qux' => [ nil,    'html' ]
    #   }
    def all_files_in(dir_name)
      # Get all good file names
      filenames = Dir[dir_name + '/**/*'].select { |i| File.file?(i) }
      filenames.reject! { |fn| fn =~ /(~|\.orig|\.rej|\.bak)$/ }

      # Group by identifier
      grouped_filenames = filenames.group_by { |fn| basename_of(fn) }

      # Convert values into metafile/content file extension tuple
      grouped_filenames.each_pair do |key, filenames|
        # Divide
        meta_filenames    = filenames.select { |fn| ext_of(fn) == '.yaml' }
        content_filenames = filenames.select { |fn| ext_of(fn) != '.yaml' }

        # Check number of files per type
        if ![ 0, 1 ].include?(meta_filenames.size)
          raise RuntimeError, "Found #{meta_filenames.size} meta files for #{key}; expected 0 or 1"
        end
        if ![ 0, 1 ].include?(content_filenames.size)
          raise RuntimeError, "Found #{content_filenames.size} content files for #{key}; expected 0 or 1"
        end

        # Reorder elements and convert to extnames
        filenames[0] = meta_filenames[0]    ? ext_of(meta_filenames[0])[1..-1]    : nil
        filenames[1] = content_filenames[0] ? ext_of(content_filenames[0])[1..-1] : nil
      end

      # Done
      grouped_filenames
    end

    # Returns the identifier for the given filename. This method assumes that
    # the base is already stripped.
    #
    # For example:
    #
    #   /foo.yaml           -> /foo/
    #   /foo/index.yaml     -> /foo/
    #   /foo/index.erb      -> /foo/
    #   /foo/foo.yaml       -> /foo/foo/
    #   /foo/bar.html       -> /foo/bar/
    #   /foo/bar.entry.yaml -> /foo/bar.entry/
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

    # Returns the base name of filename, i.e. filename with the first or all
    # extensions stripped off. By default, all extensions are stripped off,
    # but when allow_periods_in_identifiers is set to true in the site
    # configuration, only the last extension will be stripped .
    def basename_of(filename)
      filename.sub(extension_regex, '')
    end

    # Returns the extension(s) of filename. Supports multiple extensions.
    # Includes the leading period.
    def ext_of(filename)
      filename =~ extension_regex ? $1 : ''
    end

    # Returns a regex that is used for determining the extension of a file
    # name. The first match group will be the entire extension, including the
    # leading period.
    def extension_regex
      if @config && @config[:allow_periods_in_identifiers]
        /(\.[^\/\.]+$)/
      else
        /(\.[^\/]+$)/
      end
    end

  end

end
