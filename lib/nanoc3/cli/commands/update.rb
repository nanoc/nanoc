# encoding: utf-8

module Nanoc3::CLI::Commands

  class Update < Cri::Command

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
      "nanoc3 update [options]"
    end

    def option_definitions
      [
        # --vcs
        {
          :long => 'vcs', :short => 'c', :argument => :required,
          :desc => 'select the VCS to use'
        },
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
      @base.site.load_data

      # Set VCS if possible
      @base.set_vcs(options[:vcs])

      # Check for -y switch
      unless options.has_key?(:yes)
        $stderr.puts '*************'
        $stderr.puts '** WARNING **'
        $stderr.puts '*************'
        $stderr.puts
        $stderr.puts 'Are you absolutely sure you want to update the ' +
                     'content for this site? Updating the site content ' +
                     'will change the structure of existing data. This ' +
                     'operation is destructive and cannot be reverted. ' +
                     'Please do not interrupt this operation; doing so can ' +
                     'result in data loss. As always, consider making a ' +
                     'backup copy.'
        $stderr.puts
        $stderr.puts 'If this nanoc site is versioned using a VCS ' +
                     'supported by nanoc, consider using the --vcs option ' +
                     'to have nanoc perform add/delete/move operations ' +
                     'using the specified VCS. To get a list of VCSes ' +
                     'supported by nanoc, issue the "info" command.'
        $stderr.puts
        $stderr.puts 'To continue, use the -y/--yes option, like "nanoc3 ' +
                     'update -y".'
        exit 1
      end

      # Update
      @base.site.data_sources.each do |data_source|
        data_source.update
      end
    end

  end

end
