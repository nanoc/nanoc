# frozen_string_literal: true

usage 'view [options]'
summary 'start the web server that serves static files'
description <<~EOS
  Start the static web server. Unless specified, the web server will run on port
  3000 and listen on all IP addresses. Running this static web server requires
  `adsf` (not `asdf`!).
EOS

required :H, :handler, 'specify the handler to use (webrick/mongrel/...)'
required :o, :host,    'specify the host to listen on (default: 127.0.0.1)'
required :p, :port,    'specify the port to listen on (default: 3000)'

if Nanoc::Feature.enabled?(Nanoc::Feature::LIVE_RELOAD)
  flag :r, :'live-reload', 'reload on changes'
end

require 'json'

class WebSocketServer
  def initialize(host:, port:)
    @host = host
    @port = port

    @thread = start
    @sockets = []
  end

  def stop
    @thread.kill
  end

  def reload(paths)
    paths.each do |path|
      data =
        JSON.dump(
          command: 'reload',
          path:    "#{Dir.pwd}/#{path}",
        )

      @sockets.each { |ws| ws.send(data) }
    end
  end

  private

  def start
    Thread.new do
      Thread.current.abort_on_exception = true
      run
    end
  end

  def run
    require 'eventmachine'
    require 'em-websocket'

    EventMachine.run do
      EventMachine.start_server(@host, @port, EventMachine::WebSocket::Connection, {}) do |socket|
        socket.onopen  { on_socket_connected(socket) }
        socket.onclose { on_socket_disconnected(socket) }
      end
    end
  end

  def on_socket_connected(socket)
    socket.send(
      JSON.dump(
        command:    'hello',
        protocols:  ['http://livereload.com/protocols/official-7'],
        serverName: 'nanoc-view',
      ),
    )

    @sockets << socket
  end

  def on_socket_disconnected(socket)
    @sockets.delete(socket)
  end
end

class Watcher
  def initialize(root_dir:)
    unless root_dir.start_with?('/')
      raise ArgumentError, 'Watcher#initialize: The root_path argument must be an absolute path'
    end

    @root_dir = root_dir
  end

  def start
    @server = run
    @listener = start_listener(@server)
  end

  def stop
    @server.stop
    @listener.stop
  end

  def run
    WebSocketServer.new(
      host: '0.0.0.0',
      port: '35729',
    )
  end

  def start_listener(server)
    require 'listen'

    options = {
      latency: 0.0,
      wait_for_delay: 0.0,
    }

    listener =
      Listen.to('output', options) do |ch_mod, ch_add, ch_del|
        handle_changes(server, [ch_mod, ch_add, ch_del].flatten)
      end
    listener.start
    listener
  end

  def handle_changes(server, chs)
    prefix_length = @root_dir.length
    paths = chs.map { |pa| pa[prefix_length..-1] }
    server.reload(paths)
  end
end

module Nanoc::CLI::Commands
  class View < ::Nanoc::CLI::CommandRunner
    DEFAULT_HANDLER_NAME = :thin

    def run
      load_adsf
      require 'rack'

      config = Nanoc::Int::ConfigLoader.new.new_from_cwd

      # Set options
      options_for_rack = {
        Port: (options[:port] || 3000).to_i,
        Host: (options[:host] || '127.0.0.1'),
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

      # Watch for changes if in live-reload mode
      if options[:'live-reload']
        watcher = Watcher.new(root_dir: File.absolute_path(config[:output_dir]))
        watcher.start
      end

      # Build app
      option_live_reload = options[:'live-reload']
      app = Rack::Builder.new do
        use Rack::CommonLogger
        use Rack::ShowExceptions
        use Rack::Lint
        use Rack::Head
        use Adsf::Rack::IndexFileFinder,
            root: config[:output_dir],
            index_filenames: config[:index_filenames]

        if option_live_reload
          require 'rack-livereload'
          use ::Rack::LiveReload, source: :vendored
        end

        run Rack::File.new(config[:output_dir])
      end.to_app

      # Print a link
      url = "http://#{options_for_rack[:Host]}:#{options_for_rack[:Port]}/"
      puts "View the site at #{url}"

      # Run server
      handler.run(app, options_for_rack)
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

runner Nanoc::CLI::Commands::View
