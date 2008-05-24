module Nanoc::CLI

  class SetupCommand < Command

    def name
      'setup'
    end

    def aliases
      []
    end

    def short_desc
      'set up the site\'s data source'
    end

    def long_desc
      '... write me ...'
    end

    def usage
      "nanoc setup [options]"
    end

    def option_definitions
      [
        # --yes
        {
          :long => 'yes', :short => 'y', :argument => :forbidden,
          :desc => 'sets up the data source without warning'
        },
        # --datasource
        {
          :long => 'datasource', :short => 'd', :argument => :required,
          :desc => 'specify the new data source for the site'
        }
      ]
    end

    def run(options, arguments)
      # Check arguments
      if arguments.size != 0
        puts "usage: #{usage}"
        exit 1
      end

      # Check options
      unless options.has_key?(:datasource)
        puts 'A new data source should be specified using the ' +
             '-d/--datasource option.'
        exit 1
      end

      # Extract options
      data_source = options[:datasource]

      # Check whether data source exists
      if Nanoc::PluginManager.instance.data_source(data_source.to_sym).nil?
        puts "Unrecognised data source: #{data_source}"
        exit 1
      end

      # Make sure we are in a nanoc site directory
      if @base.site.nil?
        puts 'The current working directory does not seem to be a ' +
             'valid/complete nanoc site directory; aborting.'
        exit 1
      end

      # Check for -y switch
      unless options.has_key?(:yes)
        puts 'Are you absolutely sure you want to set up the data source ' +
             'for this site? Setting up the data source will remove ' +
             'existing data. To continue, use the -y/--yes option, like ' +
             '"nanoc setup -y".'
        exit 1
      end

      # Setup
      # FIXME this obviously can't work, because Site#load_data fails because it's using the wrong data source...
      @base.site.setup
    end

  end

end
