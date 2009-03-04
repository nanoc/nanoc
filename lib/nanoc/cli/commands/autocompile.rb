module Nanoc::CLI

  class AutocompileCommand < Cri::Command # :nodoc:

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
      handler_names = Nanoc::Extra::AutoCompiler::HANDLER_NAMES.join(', ')

      'Start the autocompiler web server. Unless specified, the web ' +
      'server will run on port 3000 and listen on all IP addresses. ' +
      'Running the autocompiler requires \'mime/types\' and \'rack\'.' +
      "\n" +
      'Available handlers are (in order of preference): ' + handler_names +
      ' (default is ' + Nanoc::Extra::AutoCompiler::HANDLER_NAMES[0].to_s + ').'
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
        },
        # --handler
        {
          :long => 'handler', :short => 'H', :argument => :required,
          :desc => 'specify the handler to use'
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

      # Autocompile site
      begin
        autocompiler = Nanoc::Extra::AutoCompiler.new(@base.site, options.has_key?(:all))
        autocompiler.start(
          options[:port],
          options[:handler]
        )
      rescue LoadError
        $stderr.puts "'mime/types' and 'rack' are required to autocompile sites. " +
                     "You may want to install the 'mime-types' and 'rack' gems by " +
                     "running 'gem install mime-types' and 'gem install rack'."
      rescue Nanoc::Extra::AutoCompiler::UnknownHandlerError
        $stderr.puts "The requested handler, #{options[:handler]}, is not available."
      end
    end

  end

end
