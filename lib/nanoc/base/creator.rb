module Nanoc
  class Creator

    def create_site(sitename, data_source='filesystem')
      # Check whether site exists
      error "A site named '#{sitename}' already exists." if File.exist?(sitename)

      # Create data source
      data_source_class = PluginManager.data_source_named(data_source)
      error "Unrecognised data source: #{data_source}" if data_source_class.nil?

      # Create site
      FileManager.create_dir sitename do

        # Create output
        FileManager.create_dir 'output'

        # Create config
        FileManager.create_file 'config.yaml' do
          "output_dir:  \"output\"\n" +
          "data_source: \"#{data_source}\""
        end

        # Create page defaults
        FileManager.create_file 'meta.yaml' do
          "# This file contains the default values for all metafiles.\n" +
          "# Other metafiles can override the contents of this one.\n" +
          "\n" +
          "# Built-in\n" +
          "layout:      \"default\"\n" +
          "filters_pre: []\n" +
          "filename:    \"index\"\n" +
          "extension:   \"html\"\n" +
          "\n" +
          "# Custom\n"
        end

        # Create rakefile
        FileManager.create_file 'Rakefile' do
          "Dir['tasks/**/*.rake'].sort.each { |rakefile| load rakefile }\n" +
          "\n" +
          "task :default do\n" +
          "  puts 'This is an example rake task.'\n" +
          "end\n"
        end

        # Create lib
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

        # Create tasks
        FileManager.create_dir 'tasks' do
          FileManager.create_file 'default.rake' do
            "task :example do\n" +
            "  puts 'This is an example rake task in tasks/default.rake.'\n" +
            "end\n"
          end
        end

      end

      in_dir(sitename) do
        # Create site
        site = Site.from_cwd

        # Start data source
        data_source = data_source_class.new(site, true)
        data_source.up

        # Set up data source
        data_source.setup

        # Create layouts
        data_source.create_layout('default')

        # Create templates
        data_source.create_template('default')

        # Create page
        template = data_source.templates.find { |t| t[:name] == 'default' }
        data_source.create_page('', template)

        # Stop data source
        data_source.down
      end

   end

  end
end
