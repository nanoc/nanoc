module Nanoc::DataSource::FilesystemDataSource

  class FilesystemDataSource < Nanoc::DataSource

    ########## Attributes ##########

    name :filesystem

    ########## Loading data ##########

    def pages
      Dir['content/**/meta.yaml'].inject([]) do |pages, filename|
        # Read metadata
        hash = YAML.load_file_and_clean(filename)

        if hash[:is_draft]
          # Skip drafts
          pages
        else
          # Get extra info
          path              = filename.sub(/^content/, '').sub('meta.yaml', '')
          content_filename  = content_filename_for_dir(File.dirname(filename), 'content files', File.dirname(filename))
          file              = File.new(content_filename)
          extras            = { :path => path, :file => file, :uncompiled_content => file.read }

          # Add to list of pages
          pages + [ hash.merge(extras) ]
        end
      end
    end

    def page_defaults
      YAML.load_file_and_clean('meta.yaml')
    end

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

    def templates
      Dir['templates/*/meta.yaml'].inject([]) do |templates, filename|
        # Get template name
        name = filename.sub(/^templates\/(.*)\/meta\.yaml$/, '\1')

        # Get file names
        meta_filename       = filename
        content_filenames_1 = 'templates/' + name + '/' + name + '.*'
        content_filenames_2 = 'templates/' + name + '/index.*'
        content_filenames   = Dir[content_filenames_1] + Dir[content_filenames_2]

        # Read files
        extension = nil
        content   = nil
        content_filenames.each do |filename|
          if File.exist?(filename)
            content   = File.read(filename)
            extension = File.extname(filename)
          end
        end
        meta = File.read(meta_filename)

        # Add it to the list of templates
        content.nil? ? templates : templates + [{
          :name       => name,
          :extension  => extension,
          :content    => content,
          :meta       => meta
        }]
      end
    end

    ########## Creating data ##########

    def create_page(path, template)
      # Make sure path does not start or end with a slash
      sanitized_path = path.gsub(/^\/+|\/+$/, '')

      # Get paths
      dir_path            = 'content/' + sanitized_path
      last_path_component = sanitized_path.sub(/.*\/([^\/]+)$/, '\1')
      meta_file_path      = dir_path + '/meta.yaml'
      content_file_path   = dir_path + '/' + last_path_component + template[:extension]

      # Make sure the page doesn't exist yet
      if File.exist?(meta_file_path)
        $stderr.puts "ERROR: A page named '#{path}' already exists." unless $quiet
        exit(1)
      end

      # Create index and meta file
      FileManager.create_file(meta_file_path)    { template[:meta] }
      FileManager.create_file(content_file_path) { template[:content] }
    end

    def create_layout(name)
      # Get details
      path = 'layouts/' + name + '.erb'

      # Make sure the layout doesn't exist yet
      if File.exist?(path)
        $stderr.puts "ERROR: A layout named '#{name}' already exists." unless $quiet
        exit(1)
      end

      # Create layout file
      FileManager.create_file(path) do
        "<html>\n\t<head>\n\t\t<title><%= @page.title %></title>\n\t<body>\n<%= @page.content %>\n\t</body>\n</html>\n"
      end
    end

    def create_template(name)
      # Get paths
      meta_file_path    = 'templates/' + name + '/meta.yaml'
      content_file_path = 'templates/' + name + '/' + name + '.txt'

      # Make sure the template doesn't exist yet
      if File.exist?(meta_file_path)
        $stderr.puts "ERROR: A template named '#{name}' already exists." unless $quiet
        exit(1)
      end

      # Create index and meta file
      FileManager.create_file(meta_file_path)    { "title: \"A New Page\"\n" }
      FileManager.create_file(content_file_path) { "Hi, I'm new here!\n" }
    end

  private

    ########## Custom functions ##########

    def content_filename_for_dir(dir, noun, context)
      # Find all files
      filename_glob_1 = dir.sub(/([^\/]+)$/, '\1/\1.*')
      filename_glob_2 = dir.sub(/([^\/]+)$/, '\1/index.*')
      filenames = Dir[filename_glob_1] + Dir[filename_glob_2]

      # Reject backups
      filenames.reject! { |f| f =~ /~$/ }

      # Make sure there is only one content file
      filenames.ensure_single(noun, context)

      # Get the first (and only one)
      filenames.first
    end

  end

end
