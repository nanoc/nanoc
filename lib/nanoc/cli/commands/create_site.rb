module Nanoc::CLI

  class CreateSiteCommand < Command # :nodoc:

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

      # Build entire site
      FileUtils.mkdir_p(path)
      in_dir([path]) do
        site_create_minimal(data_source)
        site_setup
        site_populate
      end
    end

  protected

    # Creates a configuration file and a output directory for this site, as
    # well as a rakefile and a 'tasks' directory because raking is fun.
    def site_create_minimal(data_source)
      # Create output
      FileUtils.mkdir_p('output')
      Nanoc::CLI::Logger.instance.file(:high, :create, 'output')

      # Create config
      File.open('config.yaml', 'w') do |io|
        io.write "output_dir:  \"output\"\n"
        io.write "data_source: \"#{data_source}\"\n"
        io.write "router:      \"default\"\n"
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
    end

    # Sets up the site's data source, i.e. creates the bare essentials for
    # this data source to work.
    def site_setup
      # Get site
      site = Nanoc::Site.new(YAML.load_file('config.yaml'))

      # Set up data source
      site.data_source.loading do
        site.data_source.setup do |filename|
          Nanoc::CLI::Logger.instance.file(:high, :create, filename)
        end
      end
    end

    # Populates the site with some initial data, such as a root page, a
    # default layout, a default template, and so on.
    def site_populate
      # Get site
      site = Nanoc::Site.new(YAML.load_file('config.yaml'))

      # Create page
      page = Nanoc::Page.new(
        "I'm a brand new root page. Please edit me!\n",
        { :title => 'A New Root Page' },
        '/'
      )
      page.site = site
      page.save

      # Fill page defaults
      Nanoc::Page::DEFAULTS.each_pair do |key, value|
        site.page_defaults.attributes[key] = value
      end
      site.page_defaults.save

      # Create layout
      layout = Nanoc::Layout.new(
        "<html>\n" +
        "  <head>\n" +
        "    <title><%= @page.title %></title>\n" +
        "  </head>\n" +
        "  <body>\n" +
        "<%= @page.content %>\n" +
        "  </body>\n" +
        "</html>\n",
        { :filter => 'erb' },
        '/default/'
      )
      layout.site = site
      layout.save

      # Create template
      template = Nanoc::Template.new(
        "Hi, I'm a new page!\n",
        { :title => "A New Page" },
        'default'
      )
      template.site = site
      template.save

      # Fill code
      code = Nanoc::Code.new(
        "\# All files in the 'lib' directory will be loaded\n" +
        "\# before nanoc starts compiling.\n" +
        "\n" +
        "def html_escape(str)\n" +
        "  str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('\"', '&quot;')\n" +
        "end\n" +
        "alias h html_escape\n"
      )
      code.site = site
      code.save
    end

  end

end
