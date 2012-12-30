# encoding: utf-8

usage       'autocompile [options]'
summary     'start the autocompiler'
aliases     :aco
description <<-EOS
Start the autocompiler web server. Unless overridden with commandline options
or configuration entries, the web server will run on port 3000 and listen on all
IP addresses. Running the autocompiler requires the 'mime/types' and 'rack' gems.

To specify the host and/or port options in config.yaml, you can add either (or
both) of the following:

  autocompile:
    host: '10.0.2.0'  # override the default host
    port: 4000        # override the default port

EOS

required :H, :handler, 'specify the handler to use (webrick/mongrel/…)'
required :o, :host,    'specify the host to listen on (default: 0.0.0.0)'
required :p, :port,    'specify the port to listen on (default: 3000)'

module Nanoc::CLI::Commands

  class AutoCompile < ::Nanoc::CLI::CommandRunner

    def run
      require 'rack'

      # Make sure we are in a nanoc site directory
      self.require_site
      autocompile_config = self.site.config[:autocompile] || {}

      # Set options
      options_for_rack = {
        :Port      => (options[:port] || autocompile_config[:port] || 3000).to_i,
        :Host      => (options[:host] || autocompile_config[:host] || '0.0.0.0')
      }

      # Guess which handler we should use
      unless handler = Rack::Handler.get(options[:handler])
        begin
          handler = Rack::Handler::Mongrel
        rescue LoadError => e
          handler = Rack::Handler::WEBrick
        end
      end

      # Build app
      autocompiler = Nanoc::Extra::AutoCompiler.new('.')
      app = Rack::Builder.new do
        use Rack::CommonLogger, $stderr
        use Rack::ShowExceptions
        run autocompiler
      end.to_app

      # Run autocompiler
      puts "Running on http://#{options_for_rack[:Host]}:#{options_for_rack[:Port]}/"
      handler.run(app, options_for_rack)
    end

  end

end

runner Nanoc::CLI::Commands::AutoCompile
