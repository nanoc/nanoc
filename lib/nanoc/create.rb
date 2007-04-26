require File.dirname(__FILE__) + '/file_management.rb'

module Nanoc

  def self.create_site(a_sitename)
    create_directory a_sitename do
      create_directory 'output'

      create_file 'config.yaml' do
        "output_dir: output\n"
      end

      create_file 'meta.yaml' do
        "# This file contains the default values for all metafiles.\n" +
        "# Other metafiles can override the contents of this one.\n" +
        "\n" +
        "# Built-in\n" +
        "layout: default\n" +
        "has_dependencies: false\n" +
        "filters:\n" +
        "  - markdown\n" +
        "\n" +
        "# Custom\n"
      end

      create_directory 'layout' do
        create_file 'default.rhtml' do
          "<html>\n" +
          "  <head>\n" +
          "    <title><%= @title %></title>\n" +
          "  </head>\n" +
          "  <body>\n" +
          "<%= @content %>\n" +
          "  </body>\n" +
          "</html>\n"
        end
      end

      create_directory 'lib' do
        create_file 'default.rb' do
          "\# All files in the 'lib' directory will be loaded\n" +
          "\# before nanoc starts compiling.\n"
        end
      end

      create_directory 'templates' do
        create_directory 'default' do
          create_file 'index.txt' do
            "This is a new page. Please edit me!\n"
          end
          create_file 'meta.yaml' do
            "# Built-in\n" +
            "\n" +
            "# Custom\n" +
            "title: A New Page\n"
          end
        end
      end

      create_directory 'content' do
        create_file 'index.txt' do
          "This is a sample root page. Please edit me!\n"
        end
        create_file 'meta.yaml' do
          "# Built-in\n" +
          "\n" +
          "# Custom\n" +
          "title: My New Homepage\n"
        end
      end
    end
  end

  def self.create_page(a_pagename, a_params={})
    # Sanitize page name
    if a_pagename =~ /^[\/\.]+/
      puts 'Error: page name starts with dots and/or slashes, aborting'
      return
    end

    # Create directory
    FileManagement.create_dir('content/' + a_pagename)

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
    create_directory 'templates' do
      create_directory a_templatename do
        create_file 'index.txt' do
          "This is a new page. Please edit me!\n"
        end
        create_file 'meta.yaml' do
          "# Built-in\n" +
          "\n"  +
          "# Custom\n"  +
          "title: A New Page\n"
        end
      end
    end
  end

end
