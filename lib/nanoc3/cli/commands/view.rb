# encoding: utf-8

usage       'view [options]'
summary     'start the web server that serves static files'
description <<-EOS
Start the static web server. Unless specified, the web server will run on port 3000 and listen on all IP addresses. Running the autocompiler requires 'adsf' and 'rack'.
EOS

option :H, :handler, 'specify the handler to use (webrick/mongrel/...)'
option :o, :host,    'specify the host to listen on (default: 0.0.0.0)'
option :p, :port,    'specify the port to listen on (default: 3000)'

run do |opts, args, cmd|
  Nanoc3::CLI::Commands::View.call(opts, args, cmd)
end

module Nanoc3::CLI::Commands

  class View < ::Nanoc3::CLI::Command

    def run
      require 'rack'
      require 'adsf'

      # Make sure we are in a nanoc site directory
      self.require_site

      # Set options
      options_for_rack = {
        :Port      => (options[:port] || 3000).to_i,
        :Host      => (options[:host] || '0.0.0.0')
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
      site = self.site
      app = Rack::Builder.new do
        use Rack::CommonLogger
        use Rack::ShowExceptions
        use Rack::Lint
        use Rack::Head
        use Adsf::Rack::IndexFileFinder, :root => site.config[:output_dir]
        run Rack::File.new(site.config[:output_dir])
      end.to_app

      # Run autocompiler
      handler.run(app, options_for_rack)
    end

  end

end
