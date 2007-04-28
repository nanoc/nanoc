require File.dirname(__FILE__) + '/file_management.rb'

module Nanoc

  def self.create_site(a_sitename)
    FileManager.create_dir a_sitename do
      FileManager.create_dir 'output'

      FileManager.create_file 'config.yaml' do
        "output_dir: output\n"
      end

      FileManager.create_file 'meta.yaml' do
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

      FileManager.create_file 'Rakefile' do
        "Dir['tasks/**/*.rake'].sort.each { |rakefile| load rakefile }\n"
      end

      FileManager.create_dir 'layouts' do
        FileManager.create_file 'default.rhtml' do
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

      FileManager.create_dir 'lib' do
        FileManager.create_file 'default.rb' do
          "\# All files in the 'lib' directory will be loaded\n" +
          "\# before nanoc starts compiling.\n"
        end
      end
      
      FileManager.create_dir 'tasks' do
        FileManager.create_file 'default.rake' do
          "  task :example do\n" +
          "    puts 'This is an example rake task, invoked'\n" +
          "    puts 'with \"rake example\"'\n" +
          "  end\n"
        end
      end

      FileManager.create_dir 'templates' do
        FileManager.create_dir 'default' do
          FileManager.create_file 'index.txt' do
            "This is a new page. Please edit me!\n"
          end
          FileManager.create_file 'meta.yaml' do
            "# Built-in\n" +
            "\n" +
            "# Custom\n" +
            "title: A New Page\n"
          end
        end
      end

      FileManager.create_dir 'content' do
        FileManager.create_file 'index.txt' do
          "This is a sample root page. Please edit me!\n"
        end
        FileManager.create_file 'meta.yaml' do
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
    FileManager.create_dir 'content/' do
      FileManager.create_dir a_pagename do
        FileManager.create_file 'index.txt' do
          template_index
        end
        FileManager.create_file 'meta.yaml' do
          template_meta
        end
      end
    end
  end

  def self.create_template(a_templatename)
    FileManager.create_dir 'templates' do
      FileManager.create_dir a_templatename do
        FileManager.create_file 'index.txt' do
          "This is a new page. Please edit me!\n"
        end
        FileManager.create_file 'meta.yaml' do
          "# Built-in\n" +
          "\n"  +
          "# Custom\n"  +
          "title: A New Page\n"
        end
      end
    end
  end

end
