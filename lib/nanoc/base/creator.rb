module Nanoc

  class Creator

    def create_site(sitename)
      ensure_nonexistant(sitename)

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

    def setup_database
      # FIXME the compiler shouldn't be involved in this
      nanoc_require 'active_record'
      $nanoc_compiler.prepare

      # Create table
      ActiveRecord::Schema.define do
        create_table :pages, :force => true do |t|
          t.column :content, :text
          t.column :path,    :string
          t.column :meta,    :text
        end
      end

      # Create first page
      Nanoc::DBPage.create(
        :path    => '/',
        :content => 'This is a sample root page. Please edit me!',
        :meta    => "# Built-in\n\n# Custom\ntitle: A New Page\n"
      )
    end

    def create_page(pagename, params={})
      Nanoc.ensure_in_site
      ensure_nonexistant(File.join(['content', pagename]))

      # Sanitize page name
      if pagename =~ /^[\/\.]+/
        $stderr.puts 'ERROR: page name starts with dots and/or slashes, aborting' unless $quiet
        return
      end

      # Read template
      template = params[:template] || 'default'
      template_meta_filename    = "templates/#{template}/meta.yaml"
      template_content_filename = content_filename_for_dir("templates/#{template}", 'template files', template)
      unless File.exist?(template_content_filename) and File.exist?(template_meta_filename)
        $stderr.puts 'ERROR: no such template' unless $quiet
        exit(1)
      else
        template_meta = File.read(template_meta_filename).eruby
        template_index = File.read(template_content_filename).eruby
      end

      # Create index and yaml file
      FileManager.create_dir 'content' do
        FileManager.create_dir pagename do
          page_name = pagename.sub(/.*\/([^\/]+)/, '\1')
          extension = File.extname(template_content_filename)
          FileManager.create_file "#{page_name}#{extension}" do
            template_index
          end
          FileManager.create_file 'meta.yaml' do
            template_meta
          end
        end
      end
    end

    def create_template(templatename)
      Nanoc.ensure_in_site
      ensure_nonexistant(File.join(['templates', templatename]))

      FileManager.create_dir 'templates' do
        FileManager.create_dir templatename do
          FileManager.create_file "#{templatename}.txt" do
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

  private

    def ensure_nonexistant(filename)
      if File.exist?(filename)
        $stderr.puts "ERROR: A file or directory named #{filename} already exists." unless $quiet
        exit(1)
      end
    end

  end
end
