module Nanoc::CLI

  class CreateSiteCommand < Command

    def name
      'create_site'
    end

    def aliases
      [ 'cs' ]
    end

    def short_desc
      'create a site'
    end

    def long_desc
      'Create a new site at the given path. The site will use the ' +
      'filesystem data source (but this can be changed later on). It will ' +
      'also include a few stub rakefiles to make adding new tasks easier.'
    end

    def usage
      "nanoc create_site [path]"
    end

    def option_definitions
      [
        # --datasource
        {
          :long => 'datasource', :short => 'd', :argument => :required,
          :desc => 'specify the data source for the new site'
        }
      ]
    end

    def run(options, arguments)
      # Extract arguments
      if arguments.length != 1
        puts "usage: #{usage}"
        exit 1
      end
      path        = arguments[0]
      data_source = options[:datasource] || 'filesystem'

      # Check whether site exists
      if File.exist?(path)
        puts "A site at '#{path}' already exists."
        exit 1
      end

      # Check whether data source exists
      if Nanoc::PluginManager.instance.data_source(data_source.to_sym).nil?
        puts "Unrecognised data source: #{data_source}"
        exit 1
      end

      # Create directories and files
      FileUtils.mkdir_p(path)
      in_dir([path]) do
        # Create output
        FileManager.create_dir 'output'

        # Create config
        FileManager.create_file 'config.yaml' do
          "output_dir:  \"output\"\n" +
          "data_source: \"#{data_source}\"\n"
        end

        # Create rakefile
        FileManager.create_file 'Rakefile' do
          "Dir['tasks/**/*.rake'].sort.each { |rakefile| load rakefile }\n" +
          "\n" +
          "task :default do\n" +
          "  puts 'This is an example rake task.'\n" +
          "end\n"
        end

        # Create tasks
        FileManager.create_file 'tasks/default.rake' do
          "task :example do\n" +
          "  puts 'This is an example rake task in tasks/default.rake.'\n" +
          "end\n"
        end

        # Setup site
        Nanoc::Site.new(YAML.load_file('config.yaml')).setup
      end
    end

  end

end
