module Nanoc::DataSources

  # The filesystem data source is the default data source for a new nanoc
  # site. It stores all data as files on the hard disk.
  #
  # None of the methods are documented in this file. See Nanoc::DataSource for
  # documentation on the overridden methods instead.
  #
  # = Pages
  #
  # The filesystem data source stores its pages in nested directories. Each
  # directory represents a single page. The root directory is the 'content'
  # directory.
  #
  # Every directory has a content file and a meta file. The content file
  # contains the actual page content, while the meta file contains the page's
  # metadata, formatted as YAML.
  #
  # Both content files and meta files are named after its parent directory
  # (i.e. page). For example, a page named 'foo' will have a directorynamed
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
  # = Assets
  #
  # Assets are stored in the 'assets' directory (surprise!). The structure is
  # very similar to the structure of the 'content' directory, so see the Pages
  # section for details on how this directory is structured.
  #
  # = Layouts
  #
  # Layouts are stored as directories in the 'layouts' directory. Each layout
  # contains a content file and a meta file. The content file contain the
  # actual layout, and the meta file describes how the page should be handled
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
  class Filesystem < Nanoc::DataSource

    ########## Attributes ##########

    identifier :filesystem

    ########## VCSes ##########

    attr_accessor :vcs

    def vcs
      @vcs ||= Nanoc::Extra::VCSes::Dummy.new
    end

    ########## Preparation ##########

    def up # :nodoc:
    end

    def down # :nodoc:
    end

    def setup # :nodoc:
      # Create directories
      %w( assets content layouts lib ).each do |dir|
        FileUtils.mkdir_p(dir)
        vcs.add(dir)
      end
    end

    def destroy # :nodoc:
      # Remove directories
      vcs.remove('assets')
      vcs.remove('content')
      vcs.remove('layouts')
      vcs.remove('lib')
    end

    def update # :nodoc:
      update_pages
    end

    ########## Pages ##########

    def pages # :nodoc:
      meta_filenames('content').map do |meta_filename|
        # Read metadata
        meta = YAML.load_file(meta_filename) || {}

        # Get content
        content_filename = content_filename_for_dir(File.dirname(meta_filename))
        content = File.read(content_filename)

        # Get attributes
        attributes = meta.merge(:file => Nanoc::Extra::FileProxy.new(content_filename))

        # Get identifier
        identifier = meta_filename.sub(/^content/, '').sub(/[^\/]+\.yaml$/, '')

        # Get modification times
        meta_mtime    = File.stat(meta_filename).mtime
        content_mtime = File.stat(content_filename).mtime
        mtime         = meta_mtime > content_mtime ? meta_mtime : content_mtime

        # Create page object
        Nanoc::Page.new(content, attributes, identifier, mtime)
      end
    end

    def save_page(page) # :nodoc:
      # Determine possible meta file paths
      last_component = page.identifier.split('/')[-1]
      meta_filename_worst = 'content' + page.identifier + 'index.yaml'
      meta_filename_best  = 'content' + page.identifier + (last_component || 'content') + '.yaml'

      # Get existing path
      existing_path = nil
      existing_path = meta_filename_best  if File.file?(meta_filename_best)
      existing_path = meta_filename_worst if File.file?(meta_filename_worst)

      if existing_path.nil?
        # Get filenames
        dir_path         = 'content' + page.identifier
        meta_filename    = meta_filename_best
        content_filename = 'content' + page.identifier + (last_component || 'content') + '.html'

        # Notify
        Nanoc::NotificationCenter.post(:file_created, meta_filename)
        Nanoc::NotificationCenter.post(:file_created, content_filename)

        # Create directories if necessary
        FileUtils.mkdir_p(dir_path)
      else
        # Get filenames
        meta_filename    = existing_path
        content_filename = content_filename_for_dir(File.dirname(existing_path))

        # Notify
        Nanoc::NotificationCenter.post(:file_updated, meta_filename)
        Nanoc::NotificationCenter.post(:file_updated, content_filename)
      end

      # Write files
      File.open(meta_filename,    'w') { |io| io.write(YAML.dump(page.attributes.stringify_keys)) }
      File.open(content_filename, 'w') { |io| io.write(page.content) }

      # Add to working copy if possible
      if existing_path.nil?
        vcs.add(meta_filename)
        vcs.add(content_filename)
      end
    end

    def move_page(page, new_identifier) # :nodoc:
      # TODO implement
    end

    def delete_page(page) # :nodoc:
      # TODO implement
    end

    ########## Assets ##########

    def assets # :nodoc:
      meta_filenames('assets').map do |meta_filename|
        # Read metadata
        meta = YAML.load_file(meta_filename) || {}

        # Get content
        content_filename = content_filename_for_dir(File.dirname(meta_filename))
        content = File.read(content_filename)

        # Get attributes
        attributes = { 'extension' => File.extname(content_filename)[1..-1] }.merge(meta)

        # Get identifier
        identifier = meta_filename.sub(/^assets/, '').sub(/[^\/]+\.yaml$/, '')

        # Get modification times
        meta_mtime    = File.stat(meta_filename).mtime
        content_mtime = File.stat(content_filename).mtime
        mtime         = meta_mtime > content_mtime ? meta_mtime : content_mtime

        # Create asset object
        Nanoc::Asset.new(content, attributes, identifier, mtime)
      end
    end

    def save_asset(asset) # :nodoc:
      # Determine possible meta file paths
      last_component = asset.identifier.split('/')[-1]
      meta_filename_worst = 'assets' + asset.identifier + 'index.yaml'
      meta_filename_best  = 'assets' + asset.identifier + (last_component || 'assets') + '.yaml'

      # Get existing path
      existing_path = nil
      existing_path = meta_filename_best  if File.file?(meta_filename_best)
      existing_path = meta_filename_worst if File.file?(meta_filename_worst)

      if existing_path.nil?
        # Get filenames
        dir_path         = 'assets' + asset.identifier
        meta_filename    = meta_filename_best
        content_filename = 'assets' + asset.identifier + (last_component || 'assets') + '.html'

        # Notify
        Nanoc::NotificationCenter.post(:file_created, meta_filename)
        Nanoc::NotificationCenter.post(:file_created, content_filename)

        # Create directories if necessary
        FileUtils.mkdir_p(dir_path)
      else
        # Get filenames
        meta_filename    = existing_path
        content_filename = content_filename_for_dir(File.dirname(existing_path))

        # Notify
        Nanoc::NotificationCenter.post(:file_updated, meta_filename)
        Nanoc::NotificationCenter.post(:file_updated, content_filename)
      end

      # Write files
      File.open(meta_filename,    'w') { |io| io.write(YAML.dump(asset.attributes.stringify_keys)) }
      File.open(content_filename, 'w') { |io| io.write(asset.content) }

      # Add to working copy if possible
      if existing_path.nil?
        vcs.add(meta_filename)
        vcs.add(content_filename)
      end
    end

    def move_asset(asset, new_identifier) # :nodoc:
      # TODO implement
    end

    def delete_asset(asset) # :nodoc:
      # TODO implement
    end

    ########## Layouts ##########

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
        Nanoc::Layout.new(content, attributes, identifier, mtime)
      end
    end

    def save_layout(layout) # :nodoc:
      # Get paths
      last_component    = layout.identifier.split('/')[-1]
      dir_path          = 'layouts' + layout.identifier
      meta_filename     = dir_path + last_component + '.yaml'
      content_filename  = Dir[dir_path + last_component + '.*'][0]

      if File.file?(meta_filename)
        created = false

        # Notify
        Nanoc::NotificationCenter.post(:file_updated, meta_filename)
        Nanoc::NotificationCenter.post(:file_updated, content_filename)
      else
        created = true

        # Create dir
        FileUtils.mkdir_p(dir_path)

        # Get content filename
        content_filename = dir_path + last_component + '.html'

        # Notify
        Nanoc::NotificationCenter.post(:file_created, meta_filename)
        Nanoc::NotificationCenter.post(:file_created, content_filename)
      end

      # Write files
      File.open(meta_filename,    'w') { |io| io.write(YAML.dump(layout.attributes.stringify_keys)) }
      File.open(content_filename, 'w') { |io| io.write(layout.content) }

      # Add to working copy if possible
      if created
        vcs.add(meta_filename)
        vcs.add(content_filename)
      end
    end

    def move_layout(layout, new_identifier) # :nodoc:
      # TODO implement
    end

    def delete_layout(layout) # :nodoc:
      # TODO implement
    end

    ########## Code ##########

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
      Nanoc::Code.new(snippets, mtime)
    end

    # FIXME update
    def save_code(code) # :nodoc:
      # Check whether code existed
      existed = File.file?('lib/default.rb')

      # Remove all existing code files
      Dir['lib/**/*.rb'].each do |file|
        vcs.remove(file) unless file == 'lib/default.rb'
      end

      # Notify
      if existed
        Nanoc::NotificationCenter.post(:file_updated, 'lib/default.rb')
      else
        Nanoc::NotificationCenter.post(:file_created, 'lib/default.rb')
      end

      # Write new code
      File.open('lib/default.rb', 'w') do |io|
        io.write(code.data)
      end

      # Add to working copy if possible
      vcs.add('lib/default.rb') unless existed
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

    # Raises an "outdated data format" error.
    def error_outdated
      raise RuntimeError.new(
        'This site\'s data is stored in an old format and must be updated. ' +
        'To do so, issue the \'nanoc update\' command. For help on ' +
        'updating a site\'s data, issue \'nanoc help update\'.'
      )
    end

    # Updates outdated pages (both content and meta file names).
    def update_pages
      # Update content files
      # content/foo/bar/baz/index.ext -> content/foo/bar/baz/baz.ext
      Dir['content/**/index.*'].select { |f| File.file?(f) }.each do |old_filename|
        # Determine new name
        if old_filename =~ /^content\/index\./
          new_filename = old_filename.sub(/^content\/index\./, 'content/content.')
        else
          new_filename = old_filename.sub(/([^\/]+)\/index\.([^\/]+)$/, '\1/\1.\2')
        end

        # Move
        vcs.move(old_filename, new_filename)
      end

      # Update meta files
      # content/foo/bar/baz/meta.yaml -> content/foo/bar/baz/baz.yaml
      Dir['content/**/meta.yaml'].select { |f| File.file?(f) }.each do |old_filename|
        # Determine new name
        if old_filename == 'content/meta.yaml'
          new_filename = 'content/content.yaml'
        else
          new_filename = old_filename.sub(/([^\/]+)\/meta.yaml$/, '\1/\1.yaml')
        end

        # Move
        vcs.move(old_filename, new_filename)
      end
    end

  end

end
