module Nanoc::CLI

  class UpdateCommand < Command # :nodoc:

    def name
      'update'
    end

    def aliases
      []
    end

    def short_desc
      'update the data stored by the data source to a newer version'
    end

    def long_desc
      'Update the data stored by the data source to a newer format. The ' +
      'format in which data is stored can change between releases, and ' +
      'even though backward compatibility is usually preserved, it is ' +
      'often a good idea to store the site data in a newer format so newer ' +
      'features can be taken advantage of.' +
      "\n" +
      'This command will change data, and it is therefore recommended to ' +
      'make a backup in case something goes wrong.'
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
        $stderr.puts "usage: #{usage}"
        exit 1
      end

      # Make sure we are in a nanoc site directory
      @base.require_site

      # Check for -y switch
      unless options.has_key?(:yes)
        $stderr.puts 'Are you absolutely sure you want to update the content for ' +
                     'this site? Updating the content will change the structure ' +
                     'of existing data. To continue, use the -y/--yes option, like ' +
                     '"nanoc update -y".'
        exit 1
      end

      # Set VCS if possible
      @base.set_vcs(options[:vcs])

      # Update
      @base.site.data_source.update
    end

  end

end
