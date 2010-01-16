# encoding: utf-8

module Nanoc3::CLI::Commands

  class CreateItem < Cri::Command

    def name
      'create_item'
    end

    def aliases
      [ 'ci' ]
    end

    def short_desc
      'create a item'
    end

    def long_desc
      'Create a new item in the current site. The first data source in the site configuration will be used.'
    end

    def usage
      "nanoc3 create_item [options] identifier"
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

      # Extract arguments and options
      identifier = arguments[0].cleaned_identifier

      # Make sure we are in a nanoc site directory
      @base.require_site
      @base.site.load_data

      # Set VCS if possible
      @base.set_vcs(options[:vcs])

      # Check whether item is unique
      if !@base.site.items.find { |i| i.identifier == identifier }.nil?
        $stderr.puts "An item already exists at #{identifier}. Please " +
                     "pick a unique name for the item you are creating."
        exit 1
      end

      # Setup notifications
      Nanoc3::NotificationCenter.on(:file_created) do |file_path|
        Nanoc3::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Create item
      data_source = @base.site.data_sources[0]
      data_source.create_item(
        "Hi, I'm a new item!\n",
        { :title => "A New Item" },
        identifier
      )

      puts "An item has been created at #{identifier}."
    end

  end

end
