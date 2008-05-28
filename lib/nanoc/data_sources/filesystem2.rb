module Nanoc::DataSources

  # = Pages
  #
  # The filesystem data source stores its pages in nested directories. A page
  # is represented by a single file. The root directory is the 'content'
  # directory.
  #
  # The metadata for a page is embedded into the file itself. It is stored at
  # the top of the file, between '-----' (five dashes) separators. For
  # example:
  #
  #   -----
  #   filters_pre: [ 'redcloth' ]
  #   -----
  #   h1. Hello!
  #
  # The path of a page is determined as follows. A file with an 'index.*'
  # filename, such as 'index.txt', will have the filesystem path with the
  # 'index.*' part stripped as a path. For example, 'foo/bar/index.html' will
  # have '/foo/bar/' as path.
  #
  # A file with a filename not starting with 'index.', such as 'foo.html',
  # will have a path ending in 'foo/'. For example, 'foo/bar.html' will have
  # '/foo/bar/' as path.
  #
  # Note that it is possible for two different, separate files to have the
  # same path. It is therefore recommended to avoid such situations.
  #
  # Some more examples:
  #
  #   content/index.html          --> /
  #   content/foo.html            --> /foo/
  #   content/foo/index.html      --> /foo/
  #   content/foo/bar.html        --> /foo/bar/
  #   content/foo/bar/index.html  --> /foo/bar/
  #
  # File extensions are ignored by nanoc. The file extension does not
  # determine the filters to run on it; the metadata in the file defines the
  # list of filters.
  #
  # = Page defaults
  #
  # The page defaults are loaded from a YAML-formatted file named 'meta.yaml'
  # file at the top level of the nanoc site directory.
  #
  # = Layouts
  #
  # Layouts are stored as files in the 'layouts' directory. Similar to pages,
  # each layout consists of a metadata part and a content part, separated by
  # '-----'.
  #
  # = Templates
  #
  # Templates are located in the 'templates' directory. Templates are, just
  # like pages, files consisting of a metadata part and a content part,
  # separated by '-----'.
  #
  # = Code
  #
  # Code is stored in '.rb' files in the 'lib' directory. Code can reside in
  # sub-directories.
  class Filesystem2 < Nanoc::DataSource

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

    identifier :filesystem2

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

      # Create template
      FileUtils.mkdir_p('templates')

      # Create layout
      FileUtils.mkdir_p('layouts')

      # Create code
      FileUtils.mkdir_p('lib')

      # FIXME remove this
      populate { |i| yield i }
    end

    def populate # :nodoc:
      # Create page
      File.open('content/index.txt', 'w') do |io|
        io.write "-----\n"
        io.write "# Built-in\n"
        io.write "\n"
        io.write "# Custom\n"
        io.write "title: \"A New Root Page\"\n"
        io.write "-----\n"
        io.write "I'm a brand new root page. Please edit me!\n"
      end
      yield('content/index.txt')

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
      File.open('templates/default.txt', 'w') do |io|
        io.write "-----\n"
        io.write "# Built-in\n"
        io.write "\n"
        io.write "# Custom\n"
        io.write "title: \"A New Page\"\n"
        io.write "-----\n"
        io.write "Hi, I'm a new page!\n"
      end
      yield('templates/default.txt')

      # Create layout
      File.open('layouts/default.erb', 'w') do |io|
        io.write "-----\n"
        io.write "filter: 'erb'\n"
        io.write "-----\n"
        io.write "<html>\n"
        io.write "  <head>\n"
        io.write "    <title><%= @page.title %></title>\n"
        io.write "  </head>\n"
        io.write "  <body>\n"
        io.write "<%= @page.content %>\n"
        io.write "  </body>\n"
        io.write "</html>\n"
      end
      yield('layouts/default.erb')

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
      files('content', true).map do |filename|
        # Read and parse data
        meta, content = *parse_file(filename, 'page')

        # Skip drafts
        return nil if meta[:is_draft]

        # Get attributes
        attributes = meta.merge(:file => FileProxy.new(filename))

        # Get actual path
        if filename =~ /\/index\.[^\/]+$/
          path = filename.sub(/^content/, '').sub(/index\.[^\/]+$/, '') + '/'
        else
          path = filename.sub(/^content/, '').sub(/\.[^\/]+$/, '') + '/'
        end

        # Get mtime
        mtime = File.stat(filename).mtime

        # Build page
        Nanoc::Page.new(content, attributes, path, mtime)
      end.compact
    end

    def save_page(page) # :nodoc:
      # # Get possible paths
      # # FIXME fix usage of 'path' here
      # path_best_glob  = 'content' + page.path[0..-2] + '.*'
      # path_worst_glob = 'content' + page.path + 'index.*'
      # 
      # # Get files
      # paths_best  = Dir[path_best_glob]
      # paths_worst = Dir[path_worst_glob]
      # 
      # # Find existing path
      # existing_path = nil
      # if paths_best.size > 0
      #   existing_path = paths_best.first
      # elsif paths_worst.size > 0
      #   existing_path = paths_worst.first
      # else
      #   existing_path = nil
      # end
      # 
      # unless existing_path.nil?
      #   # Update this file
      #   File.open(existing_path, 'w') { |io| io.write('lol, noob') }
      # else
      #   # Determine best path
      #   # ...
      #   
      #   # Create new file
      #   # ...
      # end

      # TODO implement
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
      # TODO implement
    end

    ########## Layouts ##########

    def layouts # :nodoc:
      files('layouts', true).map do |filename|
        # Read and parse data
        meta, content = *parse_file(filename, 'layout')

        # Get actual path
        path = filename.sub(/^layouts\//, '').sub(/\.[^\/]+$/, '')

        # Get mtime
        mtime = File.stat(filename).mtime

        # Build layout
        Nanoc::Layout.new(content, meta, path, mtime)
      end.compact
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
      files('templates', false).map do |filename|
        # Read and parse data
        meta, content = *parse_file(filename, 'template')

        # Get name
        name = filename.sub(/^templates\//, '').sub(/\.[^\/]+$/, '')

        # Get mtime
        mtime = File.stat(filename).mtime

        # Build template
        template = Nanoc::Template.new(content, meta, name)

        # Build final page hash
        {
          :extension  => File.extname(filename),
          :content    => content,
          :name       => name,
          :meta       => hash_to_yaml(meta)
        }
      end.compact
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
      # Get data
      data = Dir['lib/**/*.rb'].sort.map { |filename| File.read(filename) + "\n" }.join('')

      # Get modification time
      mtime = Dir['lib/**/*.rb'].map { |filename| File.stat(filename).mtime }.inject { |memo, mtime| memo > mtime ? mtime : memo}

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
      sanitized_path = path.sub(/^\/+/, '').sub(/\/+$/, '')

      # Get path
      file_path = 'content/' + sanitized_path + template[:extension]

      # Make sure the page doesn't exist yet
      error "A page at '#{file_path}' already exists." if File.exist?(file_path)

      # Create index and meta file
      FileManager.create_file(file_path) do
        "-----\n" +
        template[:meta] + "\n" +
        "-----\n" +
        template[:content]
      end
    end

    # FIXME outdated, remove
    def create_layout(name) # :nodoc:
      # Make sure name does not start or end with a slash
      sanitized_name = name.sub(/^\/+/, '').sub(/\/+$/, '')

      # Get path
      file_path = 'layouts/' + sanitized_name + '.erb'

      # Make sure the page doesn't exist yet
      error "A layout at '#{file_path}' already exists." if File.exist?(file_path)

      # Create index and meta file
      FileManager.create_file(file_path) do
        "-----\n" +
        "filter: 'erb'\n" +
        "-----\n" +
        "<html>\n" +
        "  <head>\n" +
        "    <title><%= @page.title %></title>\n" +
        "  </head>\n" +
        "  <body>\n" +
        "<%= @page.content %>\n" +
        "  </body>\n" +
        "</html>"
      end
    end

    # FIXME outdated, remove
    def create_template(name) # :nodoc:
      # Make sure name does not start or end with a slash
      sanitized_name = name.sub(/^\/+/, '').sub(/\/+$/, '')

      # Get path
      file_path = 'templates/' + sanitized_name + '.txt'

      # Make sure the page doesn't exist yet
      error "A template at '#{file_path}' already exists." if File.exist?(file_path)

      # Create index and meta file
      FileManager.create_file(file_path) do
        "-----\n" +
        "# Built-in\n\n# Custom\ntitle: A New Page\n" +
        "-----\n" +
        "Hi, I'm new here!\n"
      end
    end

  private

    # Returns a list of all files in +dir+, ignoring any backup files (files
    # that end with a ~).
    #
    # +recursively+:: When +true+, finds files in +dir+ as well as its
    #                 subdirectories; when +false+, only searches +dir+
    #                 itself.
    def files(dir, recursively)
      glob = File.join([dir] + (recursively ? [ '**', '*' ] : [ '*' ]))
      Dir[glob].reject { |f| File.directory?(f) or f =~ /~$/ }
    end

    # Parses the file named +filename+ and returns an array with its first
    # element a hash with the file's metadata, and with its second element the
    # file content itself.
    def parse_file(filename, kind)
      # Split file
      pieces = File.read(filename).split(/^-----/)
      error "The file '#{filename}' does not seem to be a nanoc #{kind}" if pieces.size < 3

      # Parse
      meta    = YAML.load(pieces[1])
      content = pieces[2..-1].join.strip

      [ meta, content ]
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
