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

    include Nanoc3::DataSources::FilesystemCommon

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
      meta_filenames('content').map do |meta_filename|
        # Read metadata
        meta = YAML.load_file(meta_filename) || {}

        # Get content
        content_filename = content_filename_for_meta_filename(meta_filename)
        content = File.read(content_filename)

        # Get attributes
        attributes = meta.merge(:file => Nanoc3::Extra::FileProxy.new(content_filename))

        # Get identifier
        identifier = identifier_for_meta_filename(meta_filename.sub(/^content/, ''))

        # Get modification times
        meta_mtime    = File.stat(meta_filename).mtime
        content_mtime = File.stat(content_filename).mtime
        mtime         = meta_mtime > content_mtime ? meta_mtime : content_mtime

        # Create item object
        Nanoc3::Item.new(content, attributes, identifier, mtime)
      end
    end

    def layouts
      meta_filenames('layouts').map do |meta_filename|
        # Get content
        content_filename  = content_filename_for_meta_filename(meta_filename)
        content           = File.read(content_filename)

        # Get attributes
        attributes = YAML.load_file(meta_filename) || {}

        # Get identifier
        identifier = identifier_for_meta_filename(meta_filename.sub(/^layouts\//, ''))

        # Get modification times
        meta_mtime    = File.stat(meta_filename).mtime
        content_mtime = File.stat(content_filename).mtime
        mtime         = meta_mtime > content_mtime ? meta_mtime : content_mtime

        # Create layout object
        Nanoc3::Layout.new(content, attributes, identifier, mtime)
      end
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

    # Returns the identifier for the given meta filename. This method assumes
    # that the base is already stripped. The identifier is calculated by
    # stripping the extension; if there is more than one extension, only the
    # last extension is stripped and the previous extensions will be part of
    # the identifier.
    #
    # For example:
    #
    #   /foo.yaml           -> /foo/
    #   /foo/index.yaml     -> /foo/
    #   /foo/foo.yaml       -> /foo/foo/
    #   /foo/bar.yaml       -> /foo/bar/
    #   /foo/bar.entry.yaml -> /foo/bar.entry/
    def identifier_for_meta_filename(meta_filename)
      # Split into components
      components = meta_filename.gsub(%r{(^/|/$)}, '').split('/')
      components[-1].sub!(/\.yaml$/, '')

      if components[-1] == 'index'
        components[0..-2].join('/').cleaned_identifier
      else
        components.join('/').cleaned_identifier
      end
    end

    # Returns the list of all meta files in the given base directory as well
    # as its subdirectories.
    def meta_filenames(base)
      Dir[base + '/**/*.yaml']
    end

    # Returns the filename of the content file corresponding to the given meta
    # file, ignoring any unwanted files (files that end with '~', '.orig',
    # '.rej' or '.bak')
    def content_filename_for_meta_filename(meta_filename)
      # Find all files
    	base_filename = File.basename(meta_filename, '.yaml')
    	dirname       = File.dirname(meta_filename)
    	filenames     = Dir.entries(dirname).select { |f| f =~ /^#{base_filename}\.[^.]+$/ }.map { |f| "#{dirname}/#{f}" }

      # Reject meta files
      filenames.reject! { |f| f =~ /\.yaml$/ }

      # Reject backups
      filenames.reject! { |f| f =~ /(~|\.orig|\.rej|\.bak)$/ }

      # Make sure there is only one content file
      if filenames.size != 1
        raise RuntimeError.new(
          "Expected 1 content file for the metafile #{meta_filename} but found #{filenames.size}"
        )
      end

      # Return content filename
      filenames.first
    end

  end

end
