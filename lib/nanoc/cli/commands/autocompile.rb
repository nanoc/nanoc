module Nanoc::CLI

  class AutocompileCommand < Command

    def name
      'autocompile'
    end

    def aliases
      [ 'aco', 'autocompile_site' ]
    end

    def short_desc
      'start the autocompiler'
    end

    def long_desc
      'Starts the autocompiler web server. Unless specified, the web ' +
      'server will run on port 3000 and listen on all IP addresses. ' +
      'Running the autocompiler requires the \'mime-types\' Ruby gem.'
    end

    def usage
      "nanoc autocompile [options]"
    end

    def option_definitions
      [
        # --all
        {
          :long => 'all', :short => 'a', :argument => :forbidden,
          :desc => 'compile all pages, even those that aren\'t outdated'
        },
        # --port
        {
          :long => 'port', :short => 'p', :argument => :required,
          :desc => 'specify a port number for the autocompiler'
        }
      ]
    end

    def run(options, arguments)
      # Make sure we are in a nanoc site directory
      if @base.site.nil?
        puts 'The current working directory does not seem to be a ' +
             'valid/complete nanoc site directory; aborting.'
        exit 1
      end

      # Autocompile site
      autocompiler = Nanoc::AutoCompiler.new(@base.site, options.has_key?(:all))
      autocompiler.start(options[:port] || 3000)
    end

  end

end
