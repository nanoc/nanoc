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
  # Content file extensions are ignored by nanoc. The content file extension
  # does not determine the filters to run on it; the meta file defines the
  # list of filters. The meta file extension must always be 'yaml', though.
  #
  # Content files can also have the 'index' basename. Similarly, meta files
  # can have the 'meta' basename. For example, a parent directory named 'foo'
  # can have an 'index.txt' content file and a 'meta.yaml' meta file. This is
  # to preserve backward compatibility.
  #
  # = Page defaults
  #
  # The page defaults are loaded from a YAML-formatted file named 'meta.yaml'
  # file at the top level of the nanoc site directory.
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
  # = Templates
  #
  # Templates are located in the 'templates' directroy. Every template is a
  # directory consisting of a content file and a meta file, both named after
  # the template. This is very similar to the way pages are stored, except
  # that templates cannot be nested.
  #
  # = Code
  #
  # Code is stored in '.rb' files in the 'lib' directory. Code can reside in
  # sub-directories.
  class Filesystem < Nanoc::DataSource

    ########## Attributes ##########

    identifier :filesystem

    ########## Preparation ##########

    def up # :nodoc:
    end

    def down # :nodoc:
    end

    def setup # :nodoc:
      # Create pages
      FileUtils.mkdir_p('content')

      # Create templates
      FileUtils.mkdir_p('templates')

      # Create layouts
      FileUtils.mkdir_p('layouts')

      # Create code
      FileUtils.mkdir_p('lib')
    end

    def destroy # :nodoc:
      # Remove files
      FileUtils.remove_entry_secure('asset_defaults.yaml')  if File.file?('asset_defaults.yaml')
      FileUtils.remove_entry_secure('meta.yaml')            if File.file?('meta.yaml')
      FileUtils.remove_entry_secure('page_defaults.yaml')   if File.file?('page_defaults.yaml')

      # Remove directories
      FileUtils.remove_entry_secure('content')
      FileUtils.remove_entry_secure('templates')
      FileUtils.remove_entry_secure('layouts')
      FileUtils.remove_entry_secure('lib')
    end

    def update # :nodoc:
      update_page_defaults
      update_pages
      update_layouts
      update_templates
    end

    ########## Pages ##########

    def pages # :nodoc:
      meta_filenames('content').map do |meta_filename|
        # Read metadata
        meta = YAML.load_file(meta_filename) || {}

        if meta['is_draft']
          # Skip drafts
          nil
        else
          # Get content
          content_filename = content_filename_for_dir(File.dirname(meta_filename))
          content = File.read(content_filename)

          # Get attributes
          attributes = meta.merge(:file => Nanoc::FileProxy.new(content_filename))

          # Get path
          path = meta_filename.sub(/^content/, '').sub(/[^\/]+\.yaml$/, '')

          # Get modification times
          meta_mtime    = File.stat(meta_filename).mtime
          content_mtime = File.stat(content_filename).mtime
          mtime         = meta_mtime > content_mtime ? meta_mtime : content_mtime

          # Create page object
          Nanoc::Page.new(content, attributes, path, mtime)
        end
      end.compact
    end

    def save_page(page) # :nodoc:
      # Determine possible meta file paths
      last_component = page.path.split('/')[-1]
      meta_filename_worst = 'content' + page.path + 'index.yaml'
      meta_filename_best  = 'content' + page.path + (last_component || 'content') + '.yaml'

      # Get existing path
      existing_path = nil
      existing_path = meta_filename_best  if File.file?(meta_filename_best)
      existing_path = meta_filename_worst if File.file?(meta_filename_worst)

      if existing_path.nil?
        # Get filenames
        dir_path         = 'content' + page.path
        meta_filename    = meta_filename_best
        content_filename = 'content' + page.path + (last_component || 'content') + '.html'

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
      File.open(meta_filename,    'w') { |io| io.write(page.attributes.to_split_yaml) }
      File.open(content_filename, 'w') { |io| io.write(page.content) }
    end

    def move_page(page, new_path) # :nodoc:
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

        # Get content file
        content_filename = content_filename_for_dir(File.dirname(meta_filename))
        content_file = File.new(content_filename)

        # Get attributes
        attributes = meta.merge(:extension => File.extname(content_filename)[1..-1])

        # Get path
        path = meta_filename.sub(/^assets/, '').sub(/[^\/]+\.yaml$/, '')

        # Get modification times
        meta_mtime    = File.stat(meta_filename).mtime
        content_mtime = File.stat(content_filename).mtime
        mtime         = meta_mtime > content_mtime ? meta_mtime : content_mtime

        # Create asset object
        Nanoc::Asset.new(content_file, attributes, path, mtime)
      end
    end

    def save_asset(asset) # :nodoc:
      # TODO implement
    end

    def move_asset(asset, new_path) # :nodoc:
      # TODO implement
    end

    def delete_asset(asset) # :nodoc:
      # TODO implement
    end

    ########## Page Defaults ##########

    def page_defaults # :nodoc:
      # Get attributes
      filename = File.file?('page_defaults.yaml') ? 'page_defaults.yaml' : 'meta.yaml'
      attributes = YAML.load_file(filename) || {}

      # Get mtime
      mtime = File.stat(filename).mtime

      # Build page defaults
      Nanoc::PageDefaults.new(attributes, mtime)
    end

    def save_page_defaults(page_defaults) # :nodoc:
      # Notify
      if File.file?('page_defaults.yaml')
        filename = 'page_defaults.yaml'
        Nanoc::NotificationCenter.post(:file_updated, filename)
      elsif File.file?('meta.yaml')
        filename = 'meta.yaml'
        Nanoc::NotificationCenter.post(:file_updated, filename)
      else
        filename = 'page_defaults.yaml'
        Nanoc::NotificationCenter.post(:file_created, 'page_defaults.yaml')
      end

      # Write
      File.open(filename, 'w') do |io|
        io.write(page_defaults.attributes.to_split_yaml)
      end
    end

    ########## Asset Defaults ##########

    def asset_defaults # :nodoc:
      if File.file?('asset_defaults.yaml')
        # Get attributes
        attributes = YAML.load_file('asset_defaults.yaml') || {}

        # Get mtime
        mtime = File.stat('asset_defaults.yaml').mtime

        # Build asset defaults
        Nanoc::AssetDefaults.new(attributes, mtime)
      else
        Nanoc::AssetDefaults.new({})
      end
    end

    def save_asset_defaults(asset_defaults) # :nodoc:
      # Notify
      if File.file?('asset_defaults.yaml')
        Nanoc::NotificationCenter.post(:file_updated, 'asset_defaults.yaml')
      else
        Nanoc::NotificationCenter.post(:file_created, 'asset_defaults.yaml')
      end

      # Write
      File.open('asset_defaults.yaml', 'w') do |io|
        io.write(asset_defaults.attributes.to_split_yaml)
      end
    end

    ########## Layouts ##########

    def layouts # :nodoc:
      # Determine what layout directory structure is being used
      dir_count = Dir[File.join('layouts', '*')].select { |f| File.directory?(f) }.size
      is_old_school = (dir_count == 0)

      if is_old_school
        # Warn about deprecation
        warn(
          'nanoc 2.1 changes the way layouts are stored. Future versions will not support these outdated sites. To update your site, issue \'nanoc update\'.',
          'DEPRECATION WARNING'
        )

        Dir[File.join('layouts', '*')].reject { |f| f =~ /~$/ }.map do |filename|
          # Get content
          content = File.read(filename)

          # Get attributes
          attributes = { :extension => File.extname(filename)}

          # Get path
          path = File.basename(filename, attributes[:extension])

          # Get modification time
          mtime = File.stat(filename).mtime

          # Create layout object
          Nanoc::Layout.new(content, attributes, path, mtime)
        end
      else
        meta_filenames('layouts').map do |meta_filename|
          # Get content
          content_filename  = content_filename_for_dir(File.dirname(meta_filename))
          content           = File.read(content_filename)

          # Get attributes
          attributes = YAML.load_file(meta_filename) || {}

          # Get path
          path = meta_filename.sub(/^layouts\//, '').sub(/\/[^\/]+\.yaml$/, '')

          # Get modification times
          meta_mtime    = File.stat(meta_filename).mtime
          content_mtime = File.stat(content_filename).mtime
          mtime         = meta_mtime > content_mtime ? meta_mtime : content_mtime

          # Create layout object
          Nanoc::Layout.new(content, attributes, path, mtime)
        end
      end
    end

    def save_layout(layout) # :nodoc:
      # Determine what layout directory structure is being used
      layout_file_count = Dir[File.join('layouts', '*')].select { |f| File.file?(f) }.size
      error_outdated if layout_file_count > 0

      # Get paths
      last_component    = layout.path.split('/')[-1]
      dir_path          = 'layouts' + layout.path
      meta_filename     = dir_path + last_component + '.yaml'
      content_filename  = Dir[dir_path + last_component + '.*'][0]

      if File.file?(meta_filename)
        # Notify
        Nanoc::NotificationCenter.post(:file_updated, meta_filename)
        Nanoc::NotificationCenter.post(:file_updated, content_filename)
      else
        # Create dir
        FileUtils.mkdir_p(dir_path)

        # Get content filename
        content_filename = dir_path + last_component + '.html'

        # Notify
        Nanoc::NotificationCenter.post(:file_created, meta_filename)
        Nanoc::NotificationCenter.post(:file_created, content_filename)
      end

      # Write files
      File.open(meta_filename,    'w') { |io| io.write(layout.attributes.to_split_yaml) }
      File.open(content_filename, 'w') { |io| io.write(layout.content) }
    end

    def move_layout(layout, new_path) # :nodoc:
      # TODO implement
    end

    def delete_layout(layout) # :nodoc:
      # TODO implement
    end

    ########## Templates ##########

    def templates # :nodoc:
      meta_filenames('templates').map do |meta_filename|
        # Get name
        name = meta_filename.sub(/^templates\/(.*)\/[^\/]+\.yaml$/, '\1')

        # Get content
        content_filename  = content_filename_for_dir(File.dirname(meta_filename))
        content           = File.read(content_filename)

        # Get attributes
        attributes = YAML.load_file(meta_filename) || {}

        # Build template
        Nanoc::Template.new(content, attributes, name)
      end
    end

    def save_template(template) # :nodoc:
      # Determine possible meta file paths
      meta_filename_worst = 'templates/' + template.name + '/index.yaml'
      meta_filename_best  = 'templates/' + template.name + '/' + template.name + '.yaml'

      # Get existing path
      existing_path = nil
      existing_path = meta_filename_best  if File.file?(meta_filename_best)
      existing_path = meta_filename_worst if File.file?(meta_filename_worst)

      if existing_path.nil?
        # Get filenames
        dir_path         = 'templates/' + template.name
        meta_filename    = meta_filename_best
        content_filename = 'templates/' + template.name + '/' + template.name + '.html'

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
      File.open(meta_filename,    'w') { |io| io.write(template.page_attributes.to_split_yaml) }
      File.open(content_filename, 'w') { |io| io.write(template.page_content) }
    end

    def move_template(template, new_name) # :nodoc:
      # TODO implement
    end

    def delete_template(template) # :nodoc:
      # TODO implement
    end

    ########## Code ##########

    def code # :nodoc:
      # Get files
      filenames = Dir['lib/**/*.rb'].sort

      # Get data
      data = filenames.map { |filename| File.read(filename) + "\n" }.join('')

      # Get modification time
      mtimes = filenames.map { |filename| File.stat(filename).mtime }
      mtime = mtimes.inject { |memo, mtime| memo > mtime ? mtime : memo }

      # Build code
      Nanoc::Code.new(data, mtime)
    end

    def save_code(code) # :nodoc:
      # Check whether code existed
      existed = File.file?('lib/default.rb')

      # Remove all existing code files
      Dir['lib/**/*.rb'].each { |f| FileUtils.remove_entry_secure(f) }

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
    end

  private

    ########## Custom functions ##########

    # Returns the list of meta files in the given base directory.
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

    # Returns a File object for the content file in the given directory
    def content_filename_for_dir(dir)
      # Find all files
      filename_glob_1 = dir.sub(/([^\/]+)$/, '\1/\1.*')
      filename_glob_2 = dir.sub(/([^\/]+)$/, '\1/index.*')
      filenames = Dir[filename_glob_1] + Dir[filename_glob_2]

      # Reject meta files
      filenames.reject! { |f| f =~ /\.yaml$/ }

      # Reject backups
      filenames.reject! { |f| f =~ /~$/ }

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

    # Updated outdated page defaults (renames page defaults file)
    def update_page_defaults
      FileUtils.mv('meta.yaml', 'page_defaults.yaml') if File.file?('meta.yaml')
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
        FileUtils.mv(old_filename, new_filename)
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
        FileUtils.mv(old_filename, new_filename)
      end
    end

    # Updates outdated layouts.
    def update_layouts # :nodoc :
      # layouts/abc.ext -> layouts/abc/abc.{html,yaml}
      Dir[File.join('layouts', '*')].select { |f| File.file?(f) }.each do |filename|
        # Get filter class
        filter_class = Nanoc::PluginManager.instance.layout_processor(File.extname(filename))

        # Get data
        content     = File.read(filename)
        attributes  = { :filter => filter_class.identifier.to_s }
        path        = File.basename(filename, File.extname(filename))

        # Get layout
        tmp_layout = Nanoc::Layout.new(content, attributes, path)

        # Get filenames
        last_component    = tmp_layout.path.split('/')[-1]
        dir_path          = 'layouts' + tmp_layout.path
        meta_filename     = dir_path + last_component + '.yaml'
        content_filename  = dir_path + last_component +  File.extname(filename)

        # Create new files
        FileUtils.mkdir_p(dir_path)
        File.open(meta_filename,    'w') { |io| io.write(tmp_layout.attributes.to_split_yaml) }
        File.open(content_filename, 'w') { |io| io.write(tmp_layout.content) }

        # Delete old files
        FileUtils.remove_entry_secure(filename)
      end
    end

    # Updates outdated templates (both content and meta file names).
    def update_templates # :nodoc :
      # Update content files
      # templates/foo/index.ext -> templates/foo/foo.ext
      Dir['templates/**/index.*'].select { |f| File.file?(f) }.each do |old_filename|
        # Determine new name
        new_filename = old_filename.sub(/([^\/]+)\/index\.([^\/]+)$/, '\1/\1.\2')

        # Move
        FileUtils.mv(old_filename, new_filename)
      end

      # Update meta files
      # templates/foo/meta.yaml -> templates/foo/foo.yaml
      Dir['templates/**/meta.yaml'].select { |f| File.file?(f) }.each do |old_filename|
        # Determine new name
        new_filename = old_filename.sub(/([^\/]+)\/meta.yaml$/, '\1/\1.yaml')

        # Move
        FileUtils.mv(old_filename, new_filename)
      end
    end

  end

end
