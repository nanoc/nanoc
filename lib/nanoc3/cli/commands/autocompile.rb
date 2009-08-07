# encoding: utf-8

module Nanoc3::CLI::Commands

  class Autocompile < Cri::Command

    def name
      'autocompile'
    end

    def aliases
      [ 'aco' ]
    end

    def short_desc
      'start the autocompiler'
    end

    def long_desc
      'Start the autocompiler web server. Unless specified, the web ' +
      'server will run on port 3000 and listen on all IP addresses. ' +
      'Running the autocompiler requires \'mime/types\' and \'rack\'.'
    end

    def usage
      "nanoc3 autocompile [options]"
    end

    def option_definitions
      [
        # --port
        {
          :long => 'port', :short => 'p', :argument => :required,
          :desc => 'specify a port number for the autocompiler'
        },
        # --server
        {
          :long => 'server', :short => 's', :argument => :required,
          :desc => 'specify the server to use (webrick/mongrel)'
        },
        # --host
        {
          :long => 'host', :short => 'o', :argument => :required,
          :desc => 'specify the host to listen on (default: 0.0.0.0)'
        },
        # --port
        {
          :long => 'port', :short => 'p', :argument => :required,
          :desc => 'specify the port to listen on (default: 3000)'
        }
      ]
    end

    def run(options, arguments)
      require 'rack'

      # Make sure we are in a nanoc site directory
      @base.require_site

      # Set options
      options_for_rack = {
        :Port      => (options[:port] || 3000).to_i,
        :Host      => (options[:host] || '0.0.0.0')
      }

      # Guess which handler we should use
      unless handler = Rack::Handler.get(options[:server])
        begin
          handler = Rack::Handler::Mongrel
        rescue LoadError => e
          handler = Rack::Handler::WEBrick
        end
      end

      # Build app
      autocompiler = Nanoc3::Extra::AutoCompiler.new(@base.site)
      app = Rack::Builder.new do
        use Rack::CommonLogger, $stderr
        use Rack::ShowExceptions
        run autocompiler
      end.to_app

      # Run autocompiler
      handler.run(app, options_for_rack)
    end

  end

end
