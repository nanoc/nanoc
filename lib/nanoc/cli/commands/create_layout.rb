module Nanoc::CLI

  class CreateLayoutCommand < Command

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
        puts "usage: #{usage}"
        exit 1
      end

      # Extract arguments
      path = arguments[0]

      # Make sure we are in a nanoc site directory
      @base.require_site

      # Create layout
      @base.site.data_source.loading do
        # FIXME don't use #create_layout
        @base.site.data_source.create_layout(path)
      end
    end

  end

end
