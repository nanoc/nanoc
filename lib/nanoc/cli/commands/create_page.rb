module Nanoc::CLI

  class CreatePageCommand < Cri::Command # :nodoc:

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
      'Create a new page in the current site. The template that will be ' +
      'used for generating the page will be \'default\', unless otherwise ' +
      'specified.'
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
        },
        # --template
        {
          :long => 'template', :short => 't', :argument => :required,
          :desc => 'specify the template for the new page'
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
      path          = arguments[0].cleaned_path
      template_name = options[:template] || 'default'

      # Make sure we are in a nanoc site directory
      @base.require_site

      # Set VCS if possible
      @base.set_vcs(options[:vcs])

      # Find template
      template = @base.site.templates.find { |t| t.name == template_name }
      if template.nil?
        $stderr.puts "A template named '#{template_name}' was not found; aborting."
        exit 1
      end

      # Setup notifications
      Nanoc::NotificationCenter.on(:file_created) do |file_path|
        Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Create page
      page = Nanoc::Page.new(
        template.page_content,
        template.page_attributes,
        path
      )
      page.site = @base.site
      page.save

      puts "A page has been created at #{path}."
    end

  end

end
