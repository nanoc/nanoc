# encoding: utf-8

usage       'view [options]'
summary     'start the web server that serves static files'
description <<-EOS
Start the static web server. Unless specified, the web server will run on port
3000 and listen on all IP addresses.
EOS

required :H, :handler, 'specify the handler to use (webrick/mongrel/...)'
required :o, :host,    'specify the host to listen on (default: 0.0.0.0)'
required :p, :port,    'specify the port to listen on (default: 3000)'

module Nanoc::CLI::Commands

  class View < ::Nanoc::CLI::CommandRunner

    DEFAULT_HANDLER_NAME = :thin

    def run
      require 'rack'

      # Make sure we are in a nanoc site directory
      require_site

      # Set options
      options_for_rack = {
        :Port      => (options[:port] || 3000).to_i,
        :Host      => (options[:host] || '0.0.0.0')
      }

      # Get handler
      if options.key?(:handler)
        handler = Rack::Handler.get(options[:handler])
      else
        begin
          handler = Rack::Handler.get(DEFAULT_HANDLER_NAME)
        rescue LoadError
          handler = Rack::Handler::WEBrick
        end
      end

      # Build app
      site = self.site
      app = Rack::Builder.new do
        use Rack::CommonLogger
        use Rack::ShowExceptions
        use Rack::Lint
        use Rack::Head
        use Rack::Static, :urls => [''], :root => site.config[:output_dir], :index => 'index.html'
        run Rack::File.new(site.config[:output_dir])
      end.to_app

      # Run autocompiler
      handler.run(app, options_for_rack)
    end

  end

end

runner Nanoc::CLI::Commands::View
