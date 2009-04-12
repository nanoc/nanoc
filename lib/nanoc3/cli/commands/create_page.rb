module Nanoc3::CLI::Commands

  class CreatePage < Cri::Command # :nodoc:

    def name
      'create_page'
    end

    def aliases
      [ 'cp' ]
    end

    def short_desc
      'create a page'
    end

    def long_desc
      'Create a new page in the current site.'
    end

    def usage
      "nanoc create_page [options] [identifier]"
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

      # Set VCS if possible
      @base.set_vcs(options[:vcs])

      # Check whether page is unique
      if !@base.site.pages.find { |l| l.identifier == identifier }.nil?
        $stderr.puts "A page already exists at #{identifier}. Please " +
                     "pick a unique name for the page you are creating."
        exit 1
      end

      # Setup notifications
      Nanoc3::NotificationCenter.on(:file_created) do |file_path|
        Nanoc3::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Create page
      base.site.data_source.create_page(
        "Hi, I'm a new page!\n",
        { :title => "A New Page" },
        identifier
      )

      puts "A page has been created at #{identifier}."
    end

  end

end
