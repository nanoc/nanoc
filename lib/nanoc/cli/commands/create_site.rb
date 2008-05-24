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
      # Check arguments
      if arguments.length != 1
        puts "usage: #{usage}"
        exit 1
      end

      # Extract arguments and options
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
        FileUtils.mkdir_p('output')
        Nanoc::CLI::Logger.instance.file(:high, :create, 'output')

        # Create config
        File.open('config.yaml', 'w') do |io|
          io.write "output_dir:  \"output\"\n"
          io.write "data_source: \"#{data_source}\"\n"
        end
        Nanoc::CLI::Logger.instance.file(:high, :create, 'config.yaml')

        # Create rakefile
        File.open('Rakefile', 'w') do |io|
          io.write "Dir['tasks/**/*.rake'].sort.each { |rakefile| load rakefile }\n"
          io.write "\n"
          io.write "task :default do\n"
          io.write "  puts 'This is an example rake task.'\n"
          io.write "end\n"
        end
        Nanoc::CLI::Logger.instance.file(:high, :create, 'Rakefile')

        # Create tasks
        FileUtils.mkdir_p('tasks')
        File.open('tasks/default.rake', 'w') do |io|
          io.write "task :example do\n"
          io.write "  puts 'This is an example rake task in tasks/default.rake.'\n"
          io.write "end\n"
        end
        Nanoc::CLI::Logger.instance.file(:high, :create, 'tasks/default.rake')

        # Setup site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.data_source.loading do
          site.data_source.setup do |filename|
            Nanoc::CLI::Logger.instance.file(:high, :create, filename)
          end
        end
      end
    end

  end

end
