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

    # A FileProxy is a proxy for a File object. It is used to prevent a File
    # object from being created until it is actually necessary.
    #
    # For example, a site with a few thousand pages would fail to compile
    # because the massive amount of file descriptors necessary, but the file
    # proxy will make sure the File object is not created until it is used.
    class FileProxy

      instance_methods.each { |m| undef_method m unless m =~ /^__/ }

      # Creates a new file proxy for the given path. This is similar to
      # creating a File object with the same path, except that the File object
      # will not be created until it is accessed.
      def initialize(path)
        @path = path
      end

      # Makes sure all method calls are relayed to a File object, which will
      # be created right before the method call takes place and destroyed
      # right after.
      def method_missing(sym, *args, &block)
        File.new(@path).__send__(sym, *args, &block)
      end

    end

    ########## Attributes ##########

    identifier :filesystem

    ########## Preparation ##########

    def up # :nodoc:
    end

    def down # :nodoc:
    end

    def setup # :nodoc:
      # Create page
      FileUtils.mkdir_p('content')

      # Create page defaults
      File.open('meta.yaml', 'w') { |io| }
      yield('meta.yaml')

      # Create templates
      FileUtils.mkdir_p('templates')

      # Create layouts
      FileUtils.mkdir_p('layouts')

      # Create code
      FileUtils.mkdir_p('lib')

      # FIXME remove this
      populate { |i| yield i }
    end

    def populate # :nodoc:
      # Create page
      FileUtils.mkdir_p('content')
      File.open('content/content.txt', 'w') do |io|
        io.write "I'm a brand new root page. Please edit me!\n"
      end
      File.open('content/content.yaml', 'w') do |io|
        io.write "# Built-in\n"
        io.write "\n"
        io.write "# Custom\n"
        io.write "title: \"A New Root Page\"\n"
      end
      yield('content/content.txt')
      yield('content/content.yaml')

      # Create page defaults
      File.open('meta.yaml', 'w') do |io|
        io.write "# This file contains the default values for all metafiles.\n"
        io.write "# Other metafiles can override the contents of this one.\n"
        io.write "\n"
        io.write "# Built-in\n"
        io.write "custom_path:  none\n"
        io.write "extension:    \"html\"\n"
        io.write "filename:     \"index\"\n"
        io.write "filters_post: []\n"
        io.write "filters_pre:  []\n"
        io.write "is_draft:     false\n"
        io.write "layout:       \"default\"\n"
        io.write "skip_output:  false\n"
        io.write "\n"
        io.write "# Custom\n"
      end
      yield('meta.yaml')

      # Create template
      FileUtils.mkdir_p('templates/default')
      File.open('templates/default/default.txt', 'w') do |io|
        io.write "Hi, I'm a new page!\n"
      end
      File.open('templates/default/default.yaml', 'w') do |io|
        io.write "# Built-in\n"
        io.write "\n"
        io.write "# Custom\n"
        io.write "title: \"A New Page\"\n"
      end
      yield('templates/default/default.txt')
      yield('templates/default/default.yaml')

      # Create layout
      FileUtils.mkdir_p('layouts/default')
      File.open('layouts/default/default.erb', 'w') do |io|
        io.write "<html>\n"
        io.write "  <head>\n"
        io.write "    <title><%= @page.title %></title>\n"
        io.write "  </head>\n"
        io.write "  <body>\n"
        io.write "<%= @page.content %>\n"
        io.write "  </body>\n"
        io.write "</html>\n"
      end
      File.open('layouts/default/default.yaml', 'w') do |io|
        io.write "filter: 'erb'\n"
      end
      yield('layouts/default/default.erb')
      yield('layouts/default/default.yaml')

      # Create code
      File.open('lib/default.rb', 'w') do |io|
        io.write "\# All files in the 'lib' directory will be loaded\n"
        io.write "\# before nanoc starts compiling.\n"
        io.write "\n"
        io.write "def html_escape(str)\n"
        io.write "  str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('\"', '&quot;')\n"
        io.write "end\n"
        io.write "alias h html_escape\n"
      end
      yield('lib/default.rb')
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
          attributes = meta.merge(:file => FileProxy.new(content_filename))

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

        # Create directories if necessary
        FileUtils.mkdir_p(dir_path)
      else
        # Get filenames
        meta_filename    = existing_path
        content_filename = content_filename_for_dir(File.dirname(existing_path))
      end

      # Write files
      File.open(meta_filename,    'w') { |io| io.write(hash_to_yaml(page.attributes)) }
      File.open(content_filename, 'w') { |io| io.write(page.content(:raw)) }
    end

    def move_page(page, new_path) # :nodoc:
      # TODO implement
    end

    def delete_page(page) # :nodoc:
      # TODO implement
    end

    ########## Page Defaults ##########

    def page_defaults # :nodoc:
      # Get attributes
      attributes = YAML.load_file('meta.yaml') || {}

      # Get mtime
      mtime = File.stat('meta.yaml').mtime

      # Build page defaults
      Nanoc::PageDefaults.new(attributes, mtime)
    end

    def save_page_defaults(page_defaults) # :nodoc:
      File.open('meta.yaml', 'w') do |io|
        io.write(hash_to_yaml(page_defaults.attributes))
      end
    end

    ########## Layouts ##########

    def layouts # :nodoc:
      # Determine what layout directory structure is being used
      dir_count = Dir[File.join('layouts', '*')].select { |f| File.directory?(f) }.size
      is_old_school = (dir_count == 0)

      if is_old_school
        # Warn about deprecation
        warn('nanoc 2.1 changes the way layouts are stored. Please see ' +
             'the nanoc web site for details on how to adjust your site.')

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
      # TODO implement
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
      # TODO implement
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
      # TODO implement
    end

    ########## OLD ##########

    # FIXME outdated, remove
    def create_page(path, template) # :nodoc:
      # Make sure path does not start or end with a slash
      sanitized_path = path.gsub(/^\/+|\/+$/, '')

      # Get paths
      dir_path      = 'content/' + sanitized_path
      name          = sanitized_path.sub(/.*\/([^\/]+)$/, '\1')
      meta_path     = dir_path + '/' + name + '.yaml'
      content_path  = dir_path + '/' + name + template[:extension]

      # Make sure the page doesn't exist yet
      error "A page named '#{path}' already exists." if File.exist?(meta_path)

      # Create index and meta file
      FileManager.create_file(meta_path)    { template[:meta] }
      FileManager.create_file(content_path) { template[:content] }
    end

    # FIXME outdated, remove
    def create_layout(name) # :nodoc:
      # Get details
      path = 'layouts/' + name

      # Make sure the layout doesn't exist yet
      error "A layout named '#{name}' already exists." if File.exist?(path)

      # Create layout file
      FileManager.create_file(path + '/' + name + '.erb') do
        "<html>\n" +
        "  <head>\n" +
        "    <title><%= @page.title %></title>\n" +
        "  </head>\n" +
        "  <body>\n" +
        "<%= @page.content %>\n" +
        "  </body>\n" +
        "</html>\n"
      end
      FileManager.create_file(path + '/' + name + '.yaml') do
        "filter: 'erb'\n"
      end
    end

    # FIXME outdated, remove
    def create_template(name) # :nodoc:
      # Get paths
      meta_path    = 'templates/' + name + '/' + name + '.yaml'
      content_path = 'templates/' + name + '/' + name + '.txt'

      # Make sure the template doesn't exist yet
      error "A template named '#{name}' already exists." if File.exist?(meta_path)

      # Create index and meta file
      FileManager.create_file(meta_path)    { "# Built-in\n\n# Custom\ntitle: A New Page\n" }
      FileManager.create_file(content_path) { "Hi, I'm new here!\n" }
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
        error "The following files appear to be meta files, " +
              "but have an invalid name:\n  - " +
              bad_filenames.join("\n  - ")
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
        error "Expected 1 content file in #{dir} but found #{filenames.size}"
      end

      # Return content filename
      filenames.first
    end

    # Converts the given hash into YAML format, splitting the YAML output into
    # a 'builtin' and a 'custom' section.
    def hash_to_yaml(hash)
      # Get list of built-in keys
      builtin_keys = Nanoc::Page::PAGE_DEFAULTS

      # Stringify keys
      hash = hash.stringify_keys

      # Split keys
      builtin_hash = hash.reject { |k,v| !builtin_keys.include?(k) }
      custom_hash  = hash.reject { |k,v| builtin_keys.include?(k) }

      # Convert to YAML
      # FIXME this is a hack, plz clean up
      '# Built-in' +
      (builtin_hash.keys.empty? ? "\n" : YAML.dump(builtin_hash).split('---')[1]) +
      "\n" +
      '# Custom' +
      (custom_hash.keys.empty? ? "\n" : YAML.dump(custom_hash).split('---')[1])
    end

  end

end
