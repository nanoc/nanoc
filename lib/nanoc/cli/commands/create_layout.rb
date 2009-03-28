module Nanoc::CLI

  class CreateLayoutCommand < Cri::Command # :nodoc:

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
      [
        # --vcs
        {
          :long => 'vcs', :short => 'c', :argument => :required,
          :desc => 'select the VCS to use'
        }
      ]
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

      # Set VCS if possible
      @base.set_vcs(options[:vcs])

      # Check whether layout is unique
      if !@base.site.layouts.find { |l| l.path == path }.nil?
        $stderr.puts "A layout already exists at #{path}. Please pick a unique name " +
                     "for the layout you are creating."
        exit 1
      end

      # Setup notifications
      Nanoc::NotificationCenter.on(:file_created) do |file_path|
        Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
      end

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

      puts "A layout has been created at #{path}."
    end

  end

end
