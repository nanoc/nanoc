module Nanoc::DataSource::FilesystemDataSource

  class FilesystemDataSource < Nanoc::DataSource

    ########## Attributes ##########

    identifier :filesystem

    ########## Loading data ##########

    # The filesystem data source stores its pages in nested directories. Each
    # directory represents a single page. The root directory is the 'content'
    # directory.
    # 
    # Every directory has a content file and a meta file. The content file
    # contains the actual page content, while the meta file contains the
    # page's metadata.
    # 
    # Both content files and meta files are named after its parent directory
    # (i.e. page). For example, a page named 'foo' will have a directory named
    # 'foo', with e.g. a 'foo.markdown' content file and a 'foo.yaml' meta
    # file.
    # 
    # Content file extensions are ignored by nanoc. The content file extension
    # does not determine the filters to run on it; the meta file defines the
    # list of filters. The meta file extension must always be 'yaml', though.
    # 
    # Content files can also have the 'index' basename. Similarly, meta files
    # can have the 'meta' basename. For example, a parent directory named
    # 'foo' can have an 'index.txt' content file and a 'meta.yaml' meta file.
    # This is to preserve backward compatibilitys.
    def pages
      meta_filenames.inject([]) do |pages, filename|
        # Read metadata
        meta = YAML.load_file_and_clean(filename)

        if meta[:is_draft]
          # Skip drafts
          pages
        else
          # Get extra info
          path    = filename.sub(/^content/, '').sub(/[^\/]+\.yaml$/, '')
          file    = content_file_for_dir(File.dirname(filename))
          extras  = {
            :path => path,
            :file => file,
            :uncompiled_content => file.read
          }

          # Add to list of pages
          pages + [ meta.merge(extras) ]
        end
      end
    end

    # The page defaults are loaded from a 'meta.yaml' file
    def page_defaults
      YAML.load_file_and_clean('meta.yaml')
    end

    # Layouts are stored as files in the 'layouts' directory. Each layout has
    # a basename (the part before the extension) and an extension. Unlike page
    # content files, the extension _is_ used for determining the layout
    # processor; which extension maps to which layout processor is defined in
    # the layout processors.
    def layouts
      Dir["layouts/*"].reject { |f| f =~ /~$/ }.map do |filename|
        # Get layout details
        extension = File.extname(filename)
        name      = File.basename(filename, extension)
        content   = File.read(filename)

        # Build hash for layout
        { :name => name, :content => content, :extension => extension }
      end
    end

    # Templates are located in the 'templates' directroy. Every template is a
    # directory consisting of a content file and a meta file, both named after
    # the template. This is very similar to the way pages are stored, except
    # that templates cannot be nested.
    def templates
      meta_filenames('templates').inject([]) do |templates, filename|
        # Get template name
        name = filename.sub(/^templates\/(.*)\/[^\/]+\.yaml$/, '\1')

        # Get file names
        meta_filename       = filename
        content_filenames_1 = 'templates/' + name + '/' + name + '.*'
        content_filenames_2 = 'templates/' + name + '/index.*'
        content_filenames   = Dir[content_filenames_1] +
                              Dir[content_filenames_2]

        # Read files
        extension = nil
        content   = nil
        content_filenames.each do |content_filename|
          content   = File.read(content_filename)
          extension = File.extname(content_filename)
        end
        meta = File.read(meta_filename)

        # Add it to the list of templates
        templates + [{
          :name       => name,
          :extension  => extension,
          :content    => content,
          :meta       => meta
        }]
      end
    end

    ########## Creating data ##########

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
      path = 'layouts/' + name + '.erb'

      # Make sure the layout doesn't exist yet
      error "A layout named '#{name}' already exists." if File.exist?(path)

      # Create layout file
      FileManager.create_file(path) do
        "<html>\n" +
        "\t<head>\n" +
        "\t\t<title><%= @page.title %></title>\n" +
        "\t</head>\n" +
        "\t<body>\n" +
        "<%= @page.content %>\n" +
        "\t</body>\n" +
        "</html>\n"
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
      FileManager.create_file(meta_path)    { "title: \"A New Page\"\n" }
      FileManager.create_file(content_path) { "Hi, I'm new here!\n" }
    end

  private

    ########## Custom functions ##########

    # Returns the list of meta files in the given (optional) base directory.
    def meta_filenames(base='content')
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
    def content_file_for_dir(dir)
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

      # Read content file
      File.new(filenames.first)
    end

  end

end
