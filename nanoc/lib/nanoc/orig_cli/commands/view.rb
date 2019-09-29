# frozen_string_literal: true

usage 'view [options]'
summary 'start the web server that serves static files'
description <<~EOS
  Start the static web server. Unless specified, the web server will run on port
  3000 and listen on all IP addresses. Running this static web server requires
  `adsf` (not `asdf`!).
EOS

required :H, :handler, 'specify the handler to use (webrick/mongrel/...)'
required :o, :host,    'specify the host to listen on (default: 127.0.0.1)', default: '127.0.0.1'
required :p, :port,    'specify the port to listen on (default: 3000)', transform: Nanoc::CLI::Transform::Port, default: 3000
flag :L, :'live-reload', 'reload on changes'
no_params

module Nanoc::OrigCLI::Commands
  class View < ::Nanoc::CLI::CommandRunner
    DEFAULT_HANDLER_NAME = :thin

    def run
      load_adsf

      config = Nanoc::Core::ConfigLoader.new.new_from_cwd

      # Create output dir so that viewer/watcher doesn’t explode.
      FileUtils.mkdir_p(config.output_dir)

      server =
        Adsf::Server.new(
          root: File.absolute_path(config.output_dir),
          live: options[:'live-reload'],
          index_filenames: config[:index_filenames],
          host: options[:host],
          port: options[:port],
          handler: options[:handler],
        )

      server.run
    end

    protected

    def load_adsf
      # Load adsf
      begin
        require 'adsf'
        return
      rescue LoadError
        $stderr.puts "Could not find the required 'adsf' gem, " \
          'which is necessary for the view command.'
      end

      # Check asdf
      begin
        require 'asdf'
        $stderr.puts "You appear to have 'asdf' installed, " \
          "but not 'adsf'. Please install 'adsf' (check the spelling)!"
      rescue LoadError
      end

      # Done
      exit 1
    end
  end
end

runner Nanoc::OrigCLI::Commands::View
