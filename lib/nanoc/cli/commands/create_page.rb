module Nanoc::CLI

  class CreatePageCommand < Command # :nodoc:

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
      "nanoc create_page [options] [path]"
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
      path = arguments[0].cleaned_path

      # Make sure we are in a nanoc site directory
      @base.require_site

      # Set VCS if possible
      @base.set_vcs(options[:vcs])

      # Setup notifications
      Nanoc::NotificationCenter.on(:file_created) do |file_path|
        Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Create page
      page = Nanoc::Page.new(
        "Hi, I'm a new page!\n",
        { :title => "A New Page" },
        path
      )
      page.site = @base.site
      @base.site.data_source.save_page(page)

      puts "A page has been created at #{path}."
    end

  end

end
