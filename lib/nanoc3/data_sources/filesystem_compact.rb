# encoding: utf-8

module Nanoc3::DataSources

  # The filesystem_combined data source is the default data source for a new
  # nanoc site. It stores all data as files on the hard disk.
  #
  # None of the methods are documented in this file. See Nanoc3::DataSource
  # for documentation on the overridden methods instead.
  #
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
  # The home page item, located at /, is represented by an index.yaml meta
  # file, along with its corresponding content file.
  #
  # Subitems of other pages can be achieved in two ways: they can either be
  # nested in directories and named "index" such as the home page item, or
  # they can simply be given a non-"index" name.
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
  #   /myst/
  #
  # = Layouts
  #
  # Layouts are stored the same way as items, except that they are stored in
  # the "layouts" directory instead of the "content" directory.
  #
  # = Code Snippets
  #
  # Code snippets are stored in '.rb' files in the 'lib' directory. Code
  # snippets can reside in sub-directories.
  class FilesystemCompact < Nanoc3::DataSource

    ########## VCSes ##########

    attr_accessor :vcs

    def vcs
      @vcs ||= Nanoc3::Extra::VCSes::Dummy.new
    end

    ########## Preparation ##########

    def setup
      # Create directories
      %w( content layouts lib ).each do |dir|
        FileUtils.mkdir_p(dir)
        vcs.add(dir)
      end
    end

    ########## Loading data ##########

    def items
      create_from_files_in('content', Nanoc3::Item)
    end

    def layouts
      create_from_files_in('layouts', Nanoc3::Layout)
    end

    ########## Creating data ##########

    # Creates a new item with the given content, attributes and identifier.
    def create_item(content, attributes, identifier)
      # Get filenames
      base_path = 'content' + (identifier == '/' ? '/index' : identifier[0..-2])
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

    # Creates a new layout with the given content, attributes and identifier.
    def create_layout(content, attributes, identifier)
      # Get filenames
      base_path = 'layouts' + identifier[0..-2]
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

  private

    ########## Custom functions ##########

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
    def all_files_in(base)
      # Get all good file names
      filenames = Dir[base + '/**/*'].select { |i| File.file?(i) }
      filenames.reject! { |fn| fn =~ /(~|\.orig|\.rej|\.bak)$/ }

      # Group by dirname+basename
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

    # Creates Item or Layout objects based on all files in the given directory.
    #
    # +base+:: The base directory where to search for files.
    #
    # +klass+:: The class (Nanoc3::Item or Nanoc3::Layout) of the objects to generate.
    def create_from_files_in(base, klass)
      all_files_in(base).map do |base_filename, (meta_ext, content_ext)|
        # Get filenames
        meta_filename    = meta_ext    ? base_filename + '.' + meta_ext    : nil
        content_filename = content_ext ? base_filename + '.' + content_ext : nil

        # Get meta and content
        meta    = (meta_filename    ? YAML.load_file(meta_filename) : nil) || {}
        content = (content_filename ? File.read(content_filename)   : nil) || ''

        # Get attributes
        attributes = {}
        attributes[:file]      = Nanoc3::Extra::FileProxy.new(content_filename) if content_filename
        attributes[:extension] = File.extname(content_filename)[1..-1]          if content_filename
        attributes.merge!(meta)

        # Get identifier
        if meta_filename
          identifier = identifier_for_filename(meta_filename[(base.length+1)..-1])
        elsif content_filename
          identifier = identifier_for_filename(content_filename[(base.length+1)..-1])
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

    # Returns the identifier for the given filename. This method assumes that
    # the base is already stripped.
    #
    # For example:
    #
    #   /foo.yaml       -> /foo/
    #   /foo/index.yaml -> /foo/
    #   /foo/index.erb  -> /foo/
    #   /foo/foo.yaml   -> /foo/foo/
    #   /foo/bar.html   -> /foo/bar/
    def identifier_for_filename(meta_filename)
      # Split into components
      components = meta_filename.gsub(%r{(^/|/$)}, '').split('/')
      components[-1].sub!(/\.[a-z0-9]+$/, '')

      if components[-1] == 'index'
        components[0..-2].join('/').cleaned_identifier
      else
        components.join('/').cleaned_identifier
      end
    end

    # Returns the base name of filename, i.e. filename with all extensions
    # stripped off. Supports multiple extensions.
    def basename_of(filename)
      filename.sub(/\.[a-z0-9]+$/, '')
    end

    # Returns the extension(s) of filename. Supports multiple extensions.
    # Includes the leading period.
    def ext_of(filename)
      filename =~ /(\.[a-z0-9]+)$/ ? $1 : ''
    end

  end

end
