module Nanoc::CLI

  class CreatePageCommand < Command

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
        puts "usage: #{usage}"
        exit 1
      end

      # Extract arguments and options
      path          = arguments[0]
      template_name = options[:template] || 'default'

      # Make sure we are in a nanoc site directory
      @base.require_site

      # Find template
      template = @base.site.templates.find { |t| t.name == template_name }
      if template.nil?
        puts "A template named '#{template_name}' was not found; aborting."
        exit 1
      end

      # Create page
      @base.site.data_source.loading do
        # FIXME don't use #create_layout
        @base.site.data_source.create_page(path, template)
      end
    end

  end

end
