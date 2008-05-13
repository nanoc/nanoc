module Nanoc::DataSources
  module Filesystem2

    class FileProxy

      instance_methods.each { |m| undef_method m unless m =~ /^__/ }

      def initialize(path)
        @path = path
      end

      def method_missing(sym, *args, &block)
        File.new(@path).__send__(sym, *args, &block)
      end

    end

    class Filesystem2DataSource < Nanoc::DataSource

      ########## Attributes ##########

      identifier :filesystem2

      ########## Preparation ##########

      def up
      end

      def down
      end

      def setup
        # Create page
        FileManager.create_file 'content/index.txt' do
          "-----\n" +
          "# Built-in\n" +
          "\n" +
          "# Custom\n" +
          "title: \"A New Root Page\"\n" +
          "-----\n" +
          "I'm a brand new root page. Please edit me!\n"
        end

        # Create page defaults
        FileManager.create_file 'meta.yaml' do
          "# This file contains the default values for all metafiles.\n" +
          "# Other metafiles can override the contents of this one.\n" +
          "\n" +
          "# Built-in\n" +
          "custom_path:  none\n" +
          "extension:    \"html\"\n" +
          "filename:     \"index\"\n" +
          "filters_post: []\n" +
          "filters_pre:  []\n" +
          "is_draft:     false\n" +
          "layout:       \"default\"\n" +
          "skip_output:  false\n" +
          "\n" +
          "# Custom\n"
        end

        # Create template
        FileManager.create_file 'templates/default.txt' do
          "-----\n" +
          "# Built-in\n" +
          "\n" +
          "# Custom\n" +
          "title: \"A New Page\"\n" +
          "-----\n" +
          "Hi, I'm a new page!\n"
        end

        # Create layout
        FileManager.create_file 'layouts/default.erb'  do
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
          "</html>\n"
        end

        # Create code
        FileManager.create_file 'lib/default.rb' do
          "\# All files in the 'lib' directory will be loaded\n" +
          "\# before nanoc starts compiling.\n" +
          "\n" +
          "def html_escape(str)\n" +
          "  str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('\"', '&quot;')\n" +
          "end\n" +
          "alias h html_escape\n"
        end

      end

      ########## Loading data ##########

      # The filesystem data source stores its pages in nested directories. A
      # page is represented by a single file. The root directory is the
      # 'content' directory.
      #
      # The metadata for a page is embedded into the file itself. It is
      # stored at the top of the file, between '-----' (five dashes)
      # separators. For example:
      #
      #   -----
      #   filters_pre: [ 'redcloth' ]
      #   -----
      #   h1. Hello!
      #
      # The path of a page is determined as follows. A file with an 'index.*'
      # filename, such as 'index.txt', will have the filesystem path with the
      # 'index.*' part stripped as a path. For example, 'foo/bar/index.html'
      # will have '/foo/bar/' as path.
      #
      # A file with a filename not starting with 'index.', such as 'foo.html',
      # will have a path ending in 'foo/'. For example, 'foo/bar.html' will
      # have '/foo/bar/' as path.
      #
      # Note that it is possible for two different, separate files to have
      # the same path. It is therefore recommended to avoid such situations.
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
      # determine the filters to run on it; the metadata in the file defines
      # the list of filters.
      def pages
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

      # The page defaults are loaded from a 'meta.yaml' file
      def page_defaults
        # Get attributes
        attributes = (YAML.load_file('meta.yaml') || {}).clean

        # Get mtime
        mtime = File.stat('meta.yaml').mtime

        # Build page defaults
        Nanoc::PageDefaults.new(attributes, mtime)
      end

      # Layouts are stored as files in the 'layouts' directory. Similar to
      # pages, each layout consists of a metadata part and a content part,
      # separated by '-----'.
      def layouts
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

      # Templates are located in the 'templates' directory. Templates are,
      # just like pages, files consisting of a metadata part and a content
      # part, separated by '-----'.
      def templates
        files('templates', false).map do |filename|
          # Split file
          pieces = File.read(filename).split(/^-----/)
          error "The file '#{filename}' does not seem to be a nanoc #{kind}" if pieces.size < 3

          # Parse
          meta    = pieces[1].strip
          content = pieces[2..-1].join.strip

          # Get name
          name = filename.sub(/^templates\//, '').sub(/\.[^\/]+$/, '')

          # Build final page hash
          {
            :extension  => File.extname(filename),
            :content    => content,
            :name       => name,
            :meta       => meta
          }
        end.compact
      end

      # Code is stored in '.rb' files in the 'lib' directory. Code can reside
      # in sub-directories.
      def code
        # Get data
        data = Dir['lib/**/*.rb'].sort.map { |filename| File.read(filename) + "\n" }.join('')

        # Get modification time
        mtime = Dir['lib/**/*.rb'].map { |filename| File.stat(filename).mtime }.inject { |memo, mtime| memo > mtime ? mtime : memo}

        # Build code
        Nanoc::Code.new(data, mtime)
      end

      ########## Creating data ##########

      # Creates a bare-bones page at the given path with the given template
      def create_page(path, template)
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

      # Creates a bare-bones layout with the given name
      def create_layout(name)
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

      # Creates a bare-bones template with the given name
      def create_template(name)
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

      def files(dir, recursively)
        Dir[dir + (recursively ? '/**/*' : '/*')].reject { |f| File.directory?(f) or f =~ /~$/ }
      end

      def parse_file(filename, kind)
        # Split file
        pieces = File.read(filename).split(/^-----/)
        error "The file '#{filename}' does not seem to be a nanoc #{kind}" if pieces.size < 3

        # Parse
        meta    = YAML.load(pieces[1]).clean
        content = pieces[2..-1].join.strip

        [ meta, content ]
      end

    end

  end
end
