# encoding: utf-8

module Nanoc3::CLI::Commands

  class CreateLayout < Cri::Command

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
      'Create a new layout in the current site. The first data source in the site configuration will be used.'
    end

    def usage
      "nanoc3 create_layout [options] identifier"
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
      identifier = arguments[0].cleaned_identifier

      # Make sure we are in a nanoc site directory
      @base.require_site
      @base.site.load_data

      # Set VCS if possible
      @base.set_vcs(options[:vcs])

      # Check whether layout is unique
      if !@base.site.layouts.find { |l| l.identifier == identifier }.nil?
        $stderr.puts "A layout already exists at #{identifier}. Please " +
                     "pick a unique name for the layout you are creating."
        exit 1
      end

      # Check whether layout is not at /
      if identifier == '/'
        $stderr.puts "There cannot be a layout with the identifier '/'; " +
                     "please pick a different identifier for this layout."
        exit 1
      end

      # Setup notifications
      Nanoc3::NotificationCenter.on(:file_created) do |file_path|
        Nanoc3::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Create layout
      data_source = @base.site.data_sources[0]
      data_source.create_layout(
        "<html>\n" +
        "  <head>\n" +
        "    <title><%= @item[:title] %></title>\n" +
        "  </head>\n" +
        "  <body>\n" +
        "    <p>Hi, I'm a new layout. Please customize me!</p>\n" +
        "<%= yield %>\n" +
        "  </body>\n" +
        "</html>\n",
        {},
        identifier
      )

      puts "A layout has been created at #{identifier}."
    end

  end

end
