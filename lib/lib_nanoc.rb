require 'bluecloth'
require 'erubis'
require 'time'
require 'yaml'

require File.dirname(__FILE__) + '/enhancements.rb'
require File.dirname(__FILE__) + '/file_management.rb'

module Nanoc
  
  DEFAULT_META = {
    :layout           => '<%= @content %>',
    :filters          => [],
    :has_dependencies => false,
    :extension        => 'html'
  }
  
  def self.create_site(a_sitename)
    # Create directories
    FileManagement.create_dir(a_sitename)
    FileManagement.create_dir(a_sitename + '/content')
    FileManagement.create_dir(a_sitename + '/layout')
    FileManagement.create_dir(a_sitename + '/output')
    
    # Create configuration
    FileManagement.create_file(a_sitename + '/config.yaml') do |io|
      io.write("output_dir: output\n")
    end
    
    # Create default meta
    FileManagement.create_file(a_sitename + '/meta.yaml') do |io|
      io.write("# This file contains the default values for all metafiles.\n")
      io.write("# Other metafiles can override the contents of this one.\n")
      io.write("\n")
      io.write("# Built-in\n")
      io.write("layout: default\n")
      io.write("has_dependencies: false\n")
      io.write("filters:\n")
      io.write("  - markdown\n")
      io.write("\n")
      io.write("# Custom\n")
    end
    
    # Create default layout
    FileManagement.create_file(a_sitename + '/layout/default.eruby') do |io|
      io.write("<html>\n")
      io.write("  <head>\n")
      io.write("    <title><%= @title %></title>\n")
      io.write("  </head>\n")
      io.write("  <body>\n")
      io.write("<%= @content %>\n")
      io.write("  </body>\n")
      io.write("</html>\n")
    end
    
    # Create home page
    FileManagement.create_file(a_sitename + '/content/index.txt') do |io|
      io.write("This is a new page. Please edit me!\n")
    end
    FileManagement.create_file(a_sitename + '/content/meta.yaml') do |io|
      io.write("# Built-in\n")
      io.write("\n")
      io.write("# Custom\n")
      io.write("title:  A New Page\n")
    end
  end
  
  def self.create_page(a_pagename)
    # Sanitize page name
    if a_pagename =~ /^[\/\.]+/
      puts 'Error: page name starts with dots and/or slashes, aborting'
      return
    end
    
    # Create directory
    FileManagement.create_dir('content/' + a_pagename, :recursive => true)
    
    # Create index and yaml file
    index_filename  = 'content/' + a_pagename + '/index.txt'
    meta_filename   = 'content/' + a_pagename + '/meta.yaml'
    FileManagement.create_file(index_filename) do |io|
      io.write("This is a new page. Please edit me!\n")
    end
    FileManagement.create_file(meta_filename) do |io|
      io.write("# Built-in\n")
      io.write("\n")
      io.write("# Custom\n")
      io.write("title:  A New Page\n")
    end
  end
  
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
      content.filter!(meta[:filters], { :pages => a_pages_without_dependencies }) unless meta[:filters].nil?
      
      # Save page
      pages << meta.merge( { :content => content })
    end
    
    pages
  end
  
end
