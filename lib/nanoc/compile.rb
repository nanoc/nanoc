require File.dirname(__FILE__) + '/enhancements.rb'
require File.dirname(__FILE__) + '/file_management.rb'

module Nanoc

  # Default configuration values
  DEFAULT_CONFIG = {
    :output_dir => 'output'
  }
  
  # Default metadata values for built-in keywords
  DEFAULT_META = {
    :layout           => '<%= @content %>',
    :filters          => [],
    :has_dependencies => false,
    :extension        => 'html'
  }

  # Filters all non-draft pages and writes them to the output directory
  def self.compile
    # Require files in lib/
    Dir.glob('lib/*.rb').each do |filename|
      require filename
    end
    
    # Load config
    config = DEFAULT_CONFIG.merge(File.read_clean_yaml('config.yaml'))

    # Get default stuff
    default_meta = DEFAULT_META.merge(File.read_clean_yaml('meta.yaml'))
    default_layout = File.read_file('layouts/' + default_meta[:layout] + '.rhtml')

    # Get all meta files
    meta_filenames = Dir.glob('content/**/meta.yaml')

    # Divide all meta files
    meta_files_without_dependencies = []
    meta_files_with_dependencies    = []
    meta_filenames.each do |meta_filename|
      # Get meta information
      meta = default_meta.merge(File.read_clean_yaml(meta_filename))

      # Skip drafts
      next if meta[:is_draft] == true

      # Put into the correct meta files array
      (meta[:has_dependencies] ? meta_files_with_dependencies : meta_files_without_dependencies) << meta_filename
    end

    # Process files, stage 1
    pages_without_dependencies  = compile_pages(default_meta, meta_files_without_dependencies, nil)
    pages_with_dependencies     = compile_pages(default_meta, meta_files_with_dependencies,    pages_without_dependencies)

    # Process files, stage 2
    pages = pages_without_dependencies + pages_with_dependencies
    pages.each do |page|
      # Get specific layout
      specific_layout = default_layout
      if page[:layout] == 'none'
        specific_layout = '<%= @content %>'
      elsif default_meta[:layout] != page[:layout]
        specific_layout = File.read_file('layouts/' + page[:layout] + '.rhtml')
      end

      # Put index file in layout
      content_with_layout = specific_layout.eruby(page.merge({ :pages => pages }))

      # Write output file
      file_path = page[:custom_path].nil? ? config[:output_dir] + page[:path] + 'index.' + page[:extension] : config[:output_dir] + page[:custom_path]
      FileManagement.create_file(file_path) do |io|
        io.write(content_with_layout)
      end
    end

  end

  private

  def self.compile_pages(a_default_meta, a_meta_filenames, a_pages_without_dependencies)
    pages = []

    # Process dynamic files
    a_meta_filenames.each do |meta_filename|
      # Get meta information
      meta = a_default_meta.merge(File.read_clean_yaml(meta_filename))

      # Get index file
      index_filenames = Dir.glob(File.dirname(meta_filename) + '/index.*')
      index_filenames.ensure_single('index files', File.dirname(meta_filename))
      index_filename = index_filenames[0]

      # Add path to meta
      meta.merge!({ :path => index_filename.sub(/^content/, '').sub(/index\.[^\/]+$/, '') })

      # Read and filter index file
      content = File.read_file(index_filename)
      content.filter!(meta[:filters], :eruby_context => { :pages => a_pages_without_dependencies }) unless meta[:filters].nil?

      # Save page
      pages << meta.merge( { :content => content })
    end

    pages
  end

end
