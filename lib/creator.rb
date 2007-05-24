module Nanoc

  class Creator

    def self.create_site(a_sitename)
      FileManager.create_dir a_sitename do
        FileManager.create_dir 'output'

        FileManager.create_file 'config.yaml' do
          "output_dir: \"output\"\n"
        end

        FileManager.create_file 'meta.yaml' do
          "# This file contains the default values for all metafiles.\n" +
          "# Other metafiles can override the contents of this one.\n" +
          "\n" +
          "# Built-in\n" +
          "layout:    \"default\"\n" +
          "order:     0\n" +
          "filters:   []\n" +
          "extension: \"html\"\n" +
          "\n" +
          "# Custom\n"
        end

        FileManager.create_file 'Rakefile' do
          "Dir['tasks/**/*.rake'].sort.each { |rakefile| load rakefile }\n" +
          "\n" +
          "task :default do\n" +
          "  puts 'This is an example rake task.'\n" +
          "end\n"
        end

        FileManager.create_dir 'layouts' do
          FileManager.create_file 'default.erb' do
            "<html>\n" +
            "  <head>\n" +
            "    <title><%= @page[:title] %></title>\n" +
            "  </head>\n" +
            "  <body>\n" +
            "<%= @page[:content] %>\n" +
            "  </body>\n" +
            "</html>\n"
          end
        end

        FileManager.create_dir 'lib' do
          FileManager.create_file 'default.rb' do
            "\# All files in the 'lib' directory will be loaded\n" +
            "\# before nanoc starts compiling.\n" +
            "\n" +
            "def html_escape(a_string)\n" +
            "  a_string.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('\\'', '&apos;').gsub('\"', '&quot;')\n" +
            "end\n" +
            "alias h html_escape\n"
          end
        end

        FileManager.create_dir 'tasks' do
          FileManager.create_file 'default.rake' do
            "task :example do\n" +
            "  puts 'This is an example rake task in tasks/default.rake.'\n" +
            "end\n"
          end
        end

        FileManager.create_dir 'templates' do
          FileManager.create_dir 'default' do
            FileManager.create_file "default.txt" do
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
          FileManager.create_file 'content.txt' do
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
      Nanoc.ensure_in_site

      # Sanitize page name
      if a_pagename =~ /^[\/\.]+/
        $stderr.puts 'ERROR: page name starts with dots and/or slashes, aborting' unless $quiet == true
        return
      end

      # Read template
      template_index = nil
      template_meta = nil
      template_content_filename = nil
      template = a_params[:template] || 'default'
      begin
        template_meta = File.read("templates/#{template}/meta.yaml")
        template_content_filenames = Dir["templates/#{template}/#{template}.*"]
        template_content_filenames += Dir["templates/#{template}/index.*"]
        template_content_filename = template_content_filenames[0]
        template_index = File.read(template_content_filename)
      rescue
        $stderr.puts 'ERROR: no such template' unless $quiet == true
        exit
      end
      template_meta = template_meta.eruby
      template_index = template_index.eruby

      # Create index and yaml file
      FileManager.create_dir 'content' do
        FileManager.create_dir a_pagename do
          FileManager.create_file "#{a_pagename.sub(/.*\/([^\/]+)/, '\1')}#{File.extname(template_content_filename)}" do
            template_index
          end
          FileManager.create_file 'meta.yaml' do
            template_meta
          end
        end
      end
    end

    def self.create_template(a_templatename)
      Nanoc.ensure_in_site

      FileManager.create_dir 'templates' do
        FileManager.create_dir a_templatename do
          FileManager.create_file "#{a_templatename}.txt" do
            "This is a new page. Please edit me!\n"
          end
          FileManager.create_file 'meta.yaml' do
            "# Built-in\n" +
            "\n" +
            "# Custom\n"  +
            "title: A New Page\n"
          end
        end
      end
    end

  end
end
