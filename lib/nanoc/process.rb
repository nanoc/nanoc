require 'bluecloth'
require 'erubis'
require 'time'
require 'yaml'

require File.dirname(__FILE__) + '/create.rb'
require File.dirname(__FILE__) + '/../enhancements.rb'
require File.dirname(__FILE__) + '/../file_management.rb'

module Nanoc

  # Default metadata values for built-in keywords
  DEFAULT_META = {
    :layout           => '<%= @content %>',
    :filters          => [],
    :has_dependencies => false,
    :extension        => 'html'
  }

  def self.process
    config = File.read_yaml('config.yaml').clean

    # Get default meta information
    default_meta = DEFAULT_META.merge(File.read_yaml('meta.yaml').clean)

    # Open layout, or simply use none
    layout = '<%= @content %>'
    unless default_meta[:layout].nil?
      layout = File.read_file('layout/' + default_meta[:layout] + '.eruby')
    end

    # Get all meta files
    meta_filenames = Dir.glob('content/**/meta.yaml')

    # Divide all meta files
    meta_files_without_dependencies = []
    meta_files_with_dependencies    = []
    meta_filenames.each do |meta_filename|
      # Get meta information
      meta = default_meta.merge(File.read_yaml(meta_filename).clean)

      # Skip drafts
      next if meta[:is_draft] == true

      # Put into the correct meta files array
      if meta[:has_dependencies] == false
        meta_files_without_dependencies << meta_filename
      else
        meta_files_with_dependencies << meta_filename
      end
    end

    # Process meta files
    pages_without_dependencies  = process_pages(default_meta, meta_files_without_dependencies, nil)
    pages_with_dependencies     = process_pages(default_meta, meta_files_with_dependencies,    pages_without_dependencies)
    pages = pages_without_dependencies + pages_with_dependencies
    pages.each do |page|
      # Get specific layout
      specific_layout = layout
      if page[:layout] == 'none'
        specific_layout = '<%= @content %>'
      elsif default_meta[:layout] != page[:layout]
        specific_layout = File.read_file('layout/' + page[:layout] + '.eruby')
      end

      # Put index file in layout
      content_with_layout = specific_layout.eruby(page.merge({ :pages => pages }))

      # Write output file
      file_path = config[:output_dir] + page[:path] + 'index.' + page[:extension]
      FileManagement.create_file(file_path, :create_dir => true, :recursive => true) do |io|
        io.write(content_with_layout)
      end
    end

  end

  private

  def self.process_pages(a_default_meta, a_meta_filenames, a_pages_without_dependencies)
    pages = []

    # Process dynamic files
    a_meta_filenames.each do |meta_filename|
      # Get meta information
      meta = a_default_meta.merge(File.read_yaml(meta_filename).clean)

      # Get index file
      index_filenames = Dir.glob(File.dirname(meta_filename) + '/index.*')

      # Check whether we have exactly one index file
      if index_filenames.empty?
        puts 'ERROR: no index files found'
        next
      elsif index_filenames.size != 1
        puts 'WARNING: multiple index files found'
      end
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
