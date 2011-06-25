# encoding: utf-8

usage       'autocompile [options]'
summary     'start the autocompiler'
aliases     :aco
description <<-EOS
Start the autocompiler web server. Unless specified, the web server will run
on port 3000 and listen on all IP addresses. Running the autocompiler requires
the 'mime/types' and 'rack' gems.
EOS

option :H, :handler, 'specify the handler to use (webrick/mongrel/...)'
option :o, :host,    'specify the host to listen on (default: 0.0.0.0)'
option :p, :port,    'specify the port to listen on (default: 3000)'

run do |opts, args, cmd|
  Nanoc3::CLI::Commands::AutoCompile.call(opts, args)
end

module Nanoc3::CLI::Commands

  class AutoCompile < ::Nanoc3::CLI::Command

    def run(options, arguments)
      require 'rack'

      # Make sure we are in a nanoc site directory
      base.require_site

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
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
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
