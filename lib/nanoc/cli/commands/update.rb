module Nanoc::CLI

  class UpdateCommand < Command # :nodoc:

    def name
      'update'
    end

    def aliases
      []
    end

    def short_desc
      'updates the data stored by the data source to a newer version'
    end

    def long_desc
      'TODO write me'
    end

    def usage
      "nanoc update [options]"
    end

    def option_definitions
      [
        # --yes
        {
          :long => 'yes', :short => 'y', :argument => :forbidden,
          :desc => 'updates the data without warning'
        }
      ]
    end

    def run(options, arguments)
      # Check arguments
      if arguments.size != 0
        puts "usage: #{usage}"
        exit 1
      end

      # Make sure we are in a nanoc site directory
      @base.require_site

      # Check for -y switch
      unless options.has_key?(:yes)
        puts 'Are you absolutely sure you want to update the content for ' +
             'this site? Updating the content will change the structure ' +
             'of existing data. To continue, use the -y/--yes option, like ' +
             '"nanoc update -y".'
        exit 1
      end

      # Update
      @base.site.data_source.update
    end

  end

end
