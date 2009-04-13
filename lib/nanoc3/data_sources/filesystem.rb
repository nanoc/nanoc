module Nanoc3::DataSources

  # The filesystem data source is the default data source for a new nanoc
  # site. It stores all data as files on the hard disk.
  #
  # None of the methods are documented in this file. See Nanoc3::DataSource
  # for documentation on the overridden methods instead.
  #
  # = Items
  #
  # The filesystem data source stores its items in nested directories. Each
  # directory represents a single item. The root directory is the 'content'
  # directory.
  #
  # Every directory has a content file and a meta file. The content file
  # contains the actual item content, while the meta file contains the item's
  # metadata, formatted as YAML.
  #
  # Both content files and meta files are named after its parent directory
  # (i.e. item). For example, a item named 'foo' will have a directory named
  # 'foo', with e.g. a 'foo.markdown' content file and a 'foo.yaml' meta file.
  #
  # Content file extensions are not used for determining the filter that
  # should be run; the meta file defines the list of filters. The meta file
  # extension must always be 'yaml', though.
  #
  # Content files can also have the 'index' basename. Similarly, meta files
  # can have the 'meta' basename. For example, a parent directory named 'foo'
  # can have an 'index.txt' content file and a 'meta.yaml' meta file. This is
  # to preserve backward compatibility.
  #
  # = Layouts
  #
  # Layouts are stored as directories in the 'layouts' directory. Each layout
  # contains a content file and a meta file. The content file contain the
  # actual layout, and the meta file describes how the item should be handled
  # (contains the filter that should be used).
  #
  # For backward compatibility, a layout can also be a single file in the
  # 'layouts' directory. Such a layout cannot have any metadata; the filter
  # used for this layout is determined from the file extension.
  #
  # = Code
  #
  # Code is stored in '.rb' files in the 'lib' directory. Code can reside in
  # sub-directories.
  class Filesystem < Nanoc3::DataSource

    ########## VCSes ##########

    attr_accessor :vcs

    def vcs
      @vcs ||= Nanoc3::Extra::VCSes::Dummy.new
    end

    ########## Preparation ##########

    def up # :nodoc:
    end

    def down # :nodoc:
    end

    def setup # :nodoc:
      # Create directories
      %w( content layouts lib ).each do |dir|
        FileUtils.mkdir_p(dir)
        vcs.add(dir)
      end
    end

    ########## Loading data ##########

    def items # :nodoc:
      meta_filenames('content').map do |meta_filename|
        # Read metadata
        meta = YAML.load_file(meta_filename) || {}

        # Get content
        content_filename = content_filename_for_dir(File.dirname(meta_filename))
        content = File.read(content_filename)

        # Get attributes
        attributes = meta.merge(:file => Nanoc3::Extra::FileProxy.new(content_filename))

        # Get identifier
        identifier = meta_filename.sub(/^content/, '').sub(/[^\/]+\.yaml$/, '')

        # Get modification times
        meta_mtime    = File.stat(meta_filename).mtime
        content_mtime = File.stat(content_filename).mtime
        mtime         = meta_mtime > content_mtime ? meta_mtime : content_mtime

        # Create item object
        Nanoc3::Item.new(content, attributes, identifier, mtime)
      end
    end

    def layouts # :nodoc:
      meta_filenames('layouts').map do |meta_filename|
        # Get content
        content_filename  = content_filename_for_dir(File.dirname(meta_filename))
        content           = File.read(content_filename)

        # Get attributes
        attributes = YAML.load_file(meta_filename) || {}

        # Get identifier
        identifier = meta_filename.sub(/^layouts\//, '').sub(/\/[^\/]+\.yaml$/, '')

        # Get modification times
        meta_mtime    = File.stat(meta_filename).mtime
        content_mtime = File.stat(content_filename).mtime
        mtime         = meta_mtime > content_mtime ? meta_mtime : content_mtime

        # Create layout object
        Nanoc3::Layout.new(content, attributes, identifier, mtime)
      end
    end

    def code # :nodoc:
      # Get files
      filenames = Dir['lib/**/*.rb'].sort

      # Read snippets
      snippets = filenames.map do |fn|
        { :filename => fn, :code => File.read(fn) }
      end

      # Get modification time
      mtimes = filenames.map { |filename| File.stat(filename).mtime }
      mtime = mtimes.inject { |memo, mtime| memo > mtime ? mtime : memo }

      # Build code
      Nanoc3::Code.new(snippets, mtime)
    end

    ########## Creating data ##########

    # Creates a new item with the given content, attributes and identifier.
    def create_item(content, attributes, identifier)
      # Determine base path
      last_component = identifier.split('/')[-1] || 'content'
      base_path = 'content' + identifier + last_component

      # Get filenames
      dir_path         = 'content' + identifier
      meta_filename    = 'content' + identifier + last_component + '.yaml'
      content_filename = 'content' + identifier + last_component + '.html'
                                     
      # Notify
      Nanoc3::NotificationCenter.post(:file_created, meta_filename)
      Nanoc3::NotificationCenter.post(:file_created, content_filename)

      # Create files
      FileUtils.mkdir_p(dir_path)
      File.open(meta_filename,    'w') { |io| io.write(YAML.dump(attributes.stringify_keys)) }
      File.open(content_filename, 'w') { |io| io.write(content) }
    end

    # Creates a new layout with the given content, attributes and identifier.
    def create_layout(content, attributes, identifier)
      # Determine base path
      last_component = identifier.split('/')[-1]
      base_path = 'layouts' + identifier + last_component

      # Get filenames
      dir_path         = 'layouts' + identifier
      meta_filename    = 'layouts' + identifier + last_component + '.yaml'
      content_filename = 'layouts' + identifier + last_component + '.html'

      # Notify
      Nanoc3::NotificationCenter.post(:file_created, meta_filename)
      Nanoc3::NotificationCenter.post(:file_created, content_filename)

      # Create files
      FileUtils.mkdir_p(dir_path)
      File.open(meta_filename,    'w') { |io| io.write(YAML.dump(attributes.stringify_keys)) }
      File.open(content_filename, 'w') { |io| io.write(content) }
    end

  private

    ########## Custom functions ##########

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

  end

end
