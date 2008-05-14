module Nanoc::DataSources
  module Filesystem

    class FileProxy

      instance_methods.each { |m| undef_method m unless m =~ /^__/ }

      def initialize(path)
        @path = path
      end

      def method_missing(sym, *args, &block)
        File.new(@path).__send__(sym, *args, &block)
      end

    end

    class FilesystemDataSource < Nanoc::DataSource

      ########## Attributes ##########

      identifier :filesystem

      ########## Preparation ##########

      def up
      end

      def down
      end

      def setup
        # Create page
        FileManager.create_file 'content/content.txt' do
          "I'm a brand new root page. Please edit me!\n"
        end
        FileManager.create_file 'content/content.yaml' do
          "# Built-in\n" +
          "\n" +
          "# Custom\n" +
          "title: \"A New Root Page\"\n"
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
        FileManager.create_file 'templates/default/default.txt' do
          "Hi, I'm a new page!\n"
        end
        FileManager.create_file 'templates/default/default.yaml' do
          "# Built-in\n" +
          "\n" +
          "# Custom\n" +
          "title: \"A New Page\"\n"
        end

        # Create layout
        FileManager.create_file 'layouts/default/default.erb'  do
          "<html>\n" +
          "  <head>\n" +
          "    <title><%= @page.title %></title>\n" +
          "  </head>\n" +
          "  <body>\n" +
          "<%= @page.content %>\n" +
          "  </body>\n" +
          "</html>\n"
        end
        FileManager.create_file 'layouts/default/default.yaml'  do
          "filter: 'erb'\n"
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

      ########## Pages ##########

      # The filesystem data source stores its pages in nested directories.
      # Each directory represents a single page. The root directory is the
      # 'content' directory.
      #
      # Every directory has a content file and a meta file. The content file
      # contains the actual page content, while the meta file contains the
      # page's metadata.
      #
      # Both content files and meta files are named after its parent directory
      # (i.e. page). For example, a page named 'foo' will have a
      # directorynamed 'foo', with e.g. a 'foo.markdown' content file and a
      # 'foo.yaml' meta file.
      #
      # Content file extensions are ignored by nanoc. The content file
      # extension does not determine the filters to run on it; the meta file
      # defines the list of filters. The meta file extension must always be
      # 'yaml', though.
      #
      # Content files can also have the 'index' basename. Similarly, meta
      # files can have the 'meta' basename. For example, a parent directory
      # named 'foo' can have an 'index.txt' content file and a 'meta.yaml'
      # meta file. This is to preserve backward compatibility.
      def pages
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

      # Saves the given page on the disk, creating it first if it's not
      # already there yet. If the page already exists, the existing path will
      # be used.
      def save_page(page)
        # Determine possible meta file paths
        last_component = page.path.split('/')[-1]
        meta_filename_worst = 'content' + page.path + 'index.yaml'
        meta_filename_best  = 'content' + page.path + (last_component || 'content') + '.yaml'

        # Get existing path
        existing_path = nil
        existing_path = meta_filename_best if File.file?(meta_filename_best)
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
        File.open(meta_filename,    'w') { |io| io.write(hash_to_yaml(page.raw_attributes)) }
        File.open(content_filename, 'w') { |io| io.write(page.content(:raw)) }
      end

      # TODO document
      def move_page(page, new_path)
        not_implemented('move_page', :optional)
      end

      # TODO document
      def delete_page(page)
        not_implemented('delete_page', :optional)
      end

      ########## Page Defaults ##########

      # The page defaults are loaded from a 'meta.yaml' file
      def page_defaults
        # Get attributes
        attributes = YAML.load_file('meta.yaml') || {}

        # Get mtime
        mtime = File.stat('meta.yaml').mtime

        # Build page defaults
        Nanoc::PageDefaults.new(attributes, mtime)
      end

      # TODO document
      def save_page_defaults(page_defaults)
        not_implemented('save_page_defaults', :optional)
      end

      ########## Layouts ##########

      # Layouts are stored as directories in the 'layouts' directory. Each
      # layout contains a content file and a meta file. The content file
      # contain the actual layout, and the meta file describes how the page
      # should be handled (contains the filter that should be used).
      def layouts
        # Determine what layout directory structure is being used
        dir_count = Dir["layouts/*"].select { |f| File.directory?(f) }.size
        is_old_school = (dir_count == 0)

        if is_old_school
          # Warn about deprecation
          # TODO fix URL
          warn('nanoc 2.1 changes the way layouts are stored. Please see ' +
               'XXX for details on how to adjust your site.')

          Dir["layouts/*"].reject { |f| f =~ /~$/ }.map do |filename|
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

      # TODO document
      def save_layout(layout)
        not_implemented('save_layout', :optional)
      end

      # TODO document
      def move_layout(layout, new_path)
        not_implemented('move_layout', :optional)
      end

      # TODO document
      def delete_layout(layout)
        not_implemented('delete_layout', :optional)
      end

      ########## Templates ##########

      # Templates are located in the 'templates' directroy. Every template is
      # a directory consisting of a content file and a meta file, both named
      # after the template. This is very similar to the way pages are stored,
      # except that templates cannot be nested.
      def templates
        meta_filenames('templates').map do |filename|
          # Get template name
          name = filename.sub(/^templates\/(.*)\/[^\/]+\.yaml$/, '\1')

          # Get file names
          meta_filename     = filename
          content_filename  = content_filename_for_dir(File.dirname(filename))

          # Add it to the list of templates
          {
            :name       => name,
            :extension  => File.extname(content_filename),
            :content    => File.read(content_filename),
            :meta       => File.read(meta_filename)
          }
        end
      end

      # TODO document
      def save_template(template)
        not_implemented('save_template', :optional)
      end

      # TODO document
      def move_template(template, new_path)
        not_implemented('move_template', :optional)
      end

      # TODO document
      def delete_template(template)
        not_implemented('delete_template', :optional)
      end

      ########## Code ##########

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

      # TODO document
      def save_code(code)
        not_implemented('save_code', :optional)
      end

      ########## OLD ##########

      # Creating a page creates a page directory with the name of the page in
      # the 'content' directory, as well as a content file named xxx.txt and a
      # meta file named xxx.yaml (with xxx being the name of the page).
      def create_page(path, template)
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

      # Creating a layout creates a single file in the 'layouts' directory,
      # named xxx.erb (with xxx being the name of the layout).
      def create_layout(name)
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

      # Creating a template creates a template directory with the name of the
      # template in the 'templates' directory, as well as a content file named
      # xxx.txt and a meta file named xxx.yaml (with xxx being the name of the
      # template).
      def create_template(name)
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

      def hash_to_yaml(hash)
        # FIXME add more keys
        builtin_keys = [ 'filters_pre' ]

        # Split keys
        builtin_hash = hash.reject { |k,v| !builtin_keys.include?(k) }
        custom_hash  = hash.reject { |k,v| builtin_keys.include?(k) }

        # Convert to YAML
        # FIXME this is a hack, plz clean up
        '# Built-in' +
        YAML.dump(builtin_hash).split('---')[1] +
        "\n" +
        '# Custom' +
        YAML.dump(custom_hash).split('---')[1]
      end

    end

  end
end
