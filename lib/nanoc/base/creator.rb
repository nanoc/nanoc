module Nanoc
  class Creator

    def create_site(sitename)
      error "A site named '#{sitename}' already exists." if File.exist?(sitename)

      FileManager.create_dir sitename do
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
          "filters:   []\n" +
          "filename:  \"index\"\n" +
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
            "    <title><%= @page.title %></title>\n" +
            "  </head>\n" +
            "  <body>\n" +
            "<%= @page.content %>\n" +
            "  </body>\n" +
            "</html>\n"
          end
        end

        FileManager.create_dir 'lib' do
          FileManager.create_file 'default.rb' do
            "\# All files in the 'lib' directory will be loaded\n" +
            "\# before nanoc starts compiling.\n" +
            "\n" +
            "def html_escape(str)\n" +
            "  str.gsub('&', '&amp;').str('<', '&lt;').str('>', '&gt;').str('\"', '&quot;')\n" +
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

  end
end
