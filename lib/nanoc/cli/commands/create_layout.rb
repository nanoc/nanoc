module Nanoc::CLI

  class CreateLayoutCommand < Command # :nodoc:

    def name
      'create_layout'
    end

    def aliases
      [ 'cl' ]
    end

    def short_desc
      'create a layout'
    end

    def long_desc
      'Create a new layout in the current site.'
    end

    def usage
      "nanoc create_layout [path]"
    end

    def option_definitions
      []
    end

    def run(options, arguments)
      # Check arguments
      if arguments.length != 1
        $stderr.puts "usage: #{usage}"
        exit 1
      end

      # Extract arguments
      path = arguments[0].cleaned_path

      # Make sure we are in a nanoc site directory
      @base.require_site

      # Check whether layout is unique
      if !@base.site.layouts.find { |l| l.path == path }.nil?
        $stderr.puts "A layout already exists at #{path}. Please pick a unique name " +
                     "for the layout you are creating." unless ENV['QUIET']
        exit 1
      end

      # Setup notifications
      Nanoc::NotificationCenter.on(:file_created) do |file_path|
        Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Set VCS if possible
      @base.set_vcs(options[:vcs])

      # Create layout
      layout = Nanoc::Layout.new(
        "<html>\n" +
        "  <head>\n" +
        "    <title><%= @page.title %></title>\n" +
        "  </head>\n" +
        "  <body>\n" +
        "    <p>Hi, I'm a new layout. Please customize me!</p>\n" +
        "<%= @page.content %>\n" +
        "  </body>\n" +
        "</html>\n",
        { :filter => 'erb' },
        path
      )
      layout.site = @base.site
      layout.save

      puts "A layout has been created at #{path}." unless ENV['QUIET']
    end

  end

end
