require File.dirname(__FILE__) + '/../file_management.rb'

module Nanoc

  def self.create_site(a_sitename)
    FileManagement.create_dir(a_sitename)
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

    # Create layouts
    FileManagement.create_dir(a_sitename + '/layout')
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

    # Create templates
    FileManagement.create_dir(a_sitename + '/templates')
    FileManagement.create_dir(a_sitename + '/templates/default')
    FileManagement.create_file(a_sitename + '/templates/default/index.txt') do |io|
      io.write("This is a new page. Please edit me!\n")
    end
    FileManagement.create_file(a_sitename + '/templates/default/meta.yaml') do |io|
      io.write("# Built-in\n")
      io.write("\n")
      io.write("# Custom\n")
      io.write("title: A New Page\n")
    end

    # Create content
    template_meta = File.read_file(a_sitename + '/templates/default/meta.yaml')
    template_index = File.read_file(a_sitename + '/templates/default/index.txt')
    FileManagement.create_dir(a_sitename + '/content')
    FileManagement.create_file(a_sitename + '/content/index.txt') do |io|
      io.write(template_index)
    end
    FileManagement.create_file(a_sitename + '/content/meta.yaml') do |io|
      io.write(template_meta)
    end
  end

  def self.create_page(a_pagename, a_params={})
    # Sanitize page name
    if a_pagename =~ /^[\/\.]+/
      puts 'Error: page name starts with dots and/or slashes, aborting'
      return
    end

    # Create directory
    FileManagement.create_dir('content/' + a_pagename, :recursive => true)

    # Read template
    template_index = nil
    template_meta = nil
    begin
      template = a_params[:template] || 'default'
      template_meta = File.read_file('templates/' + template + '/meta.yaml')
      template_index_filename = Dir.glob('templates/' + template + '/index.*')[0]
      template_index = File.read_file(template_index_filename)
    rescue
      puts 'ERROR: no such template'
      exit
    end

    # Create index and yaml file
    FileManagement.create_file('content/' + a_pagename + '/index.txt') do |io|
      io.write(template_index)
    end
    FileManagement.create_file('content/' + a_pagename + '/meta.yaml') do |io|
      io.write(template_meta)
    end
  end

  def self.create_template(a_templatename)
    # Create template
    FileManagement.create_dir('templates')
    FileManagement.create_dir('templates/' + a_templatename)
    FileManagement.create_file('templates/' + a_templatename + '/index.txt') do |io|
      io.write("This is a new page. Please edit me!\n")
    end
    FileManagement.create_file('templates/' + a_templatename + '/meta.yaml') do |io|
      io.write("# Built-in\n")
      io.write("\n")
      io.write("# Custom\n")
      io.write("title: A New Page\n")
    end
  end

end
