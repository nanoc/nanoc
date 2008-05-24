module Nanoc::CLI

  class CreateTemplateCommand < Command

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
      []
    end

    def run(options, arguments)
      # Check arguments
      if arguments.length != 1
        puts "usage: #{usage}"
        exit 1
      end

      # Extract arguments
      name = arguments[0]

      # Check template name
      if name.include?('/')
        puts 'Template names cannot contain slashes; aborting.'
        exit 1
      end

      # Make sure we are in a nanoc site directory
      if @base.site.nil?
        puts 'The current working directory does not seem to be a ' +
             'valid/complete nanoc site directory; aborting.'
        exit 1
      end

      # Create template
      @base.site.data_source.loading do
        # FIXME don't use #create_template
        @base.site.data_source.create_template(name)
      end
    end

  end

end
