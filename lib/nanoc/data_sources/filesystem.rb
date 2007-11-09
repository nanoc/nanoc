module Nanoc::DataSource::FileSystem
  
  class FileSystemDataSource < Nanoc::DataSource

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
      []
    end

  end

  register_data_source :filesystem, FileSystemDataSource

end
