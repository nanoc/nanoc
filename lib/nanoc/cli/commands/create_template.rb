module Nanoc::CLI

  class CreateTemplateCommand < Cri::Command # :nodoc:

    def name
      'create_template'
    end

    def aliases
      [ 'ct' ]
    end

    def short_desc
      'create a template'
    end

    def long_desc
      'Create a new template in the current site.'
    end

    def usage
      "nanoc create_template [name]"
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
      name = arguments[0]

      # Check template name
      if name.include?('/')
        $stderr.puts 'Template names cannot contain slashes; aborting.'
        exit 1
      end

      # Make sure we are in a nanoc site directory
      @base.require_site

      # Set VCS if possible
      @base.set_vcs(options[:vcs])

      # Setup notifications
      Nanoc::NotificationCenter.on(:file_created) do |file_path|
        Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Create template
      template = Nanoc::Template.new(
        "Hi, I'm a new template. Please edit me!",
        { :title => "A Title" },
        name
      )
      template.site = @base.site
      template.save

      puts "A template named '#{name}' has been created."
    end

  end

end
