require 'webrick'

module Nanoc::Extra

  # Nanoc::Extra::AutoCompiler is a web server that will automatically compile
  # pages as they are requested. It also serves static files such as
  # stylesheets and images.
  class AutoCompiler

    # Error that is raised when the autocompiler is started if the specified
    # handler cannot be found.
    class UnknownHandlerError < Nanoc::Error ; end

    HANDLER_NAMES = [ :thin, :mongrel, :webrick, :ebb, :cgi, :fastcgi, :lsws, :scgi ]

    ERROR_404 = <<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<title>404 File Not Found</title>
		<style type="text/css">
			body { padding: 10px; border: 10px solid #f00; margin: 10px; font-family: Helvetica, Arial, sans-serif; }
		</style>
	</head>
	<body>
		<h1>404 File Not Found</h1>
		<p>The file you requested, <i><%=h path %></i>, was not found on this server.</p>
	</body>
</html>
END

    ERROR_500 = <<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<title>500 Server Error</title>
		<style type="text/css">
			body { padding: 10px; border: 10px solid #f00; margin: 10px; font-family: Helvetica, Arial, sans-serif; }
		</style>
	</head>
	<body>
		<h1>500 Server Error</h1>
		<p>An error occurred while compiling the page you requested, <i><%=h path %></i>.</p>
		<p>If you think this is a bug in nanoc, please do <a href="http://nanoc.stoneship.org/trac/newticket">report it</a>&mdash;thanks!</p>
		<p>Message:</p>
		<blockquote><p><%=h message %></p></blockquote>
		<p>Page compilation stack:</p>
		<ol>
<% @site.compiler.stack.reverse.each do |item| %>
<%   if item.is_a?(Nanoc::PageRep) # page rep %>
			<li><strong>Page</strong> <%= item.page.path %> (rep <%= item.name %>)</li>
<% else # layout %>
			<li><strong>Layout</strong> <%= item.path %></li>
<% end %>
<% end %>
		</ol>
		<p>Backtrace:</p>
		<ol>
<% exception.backtrace.each do |line| %>
			<li><%= line %></li>
<% end %>
		</ol>
	</body>
</html>
END

    # Creates a new autocompiler for the given site.
    def initialize(site, include_outdated=false)
      # Set site
      @site = site

      # Set options
      @include_outdated = include_outdated

      # Create mutex to prevent parallel requests
      @mutex = Mutex.new
    end

    # Starts the server on the given port.
    #
    # +port+:: The port the autocompiler web server should be started on. Can
    #          be nil; in this case the server will be started on port 3000.
    #
    # +handler_name+:: A symbol containing the name of the handler to use. See
    #                  HANDLER_NAMES for a list of supported handlers. Can be
    #                  set to nil; in this case the best handler will be
    #                  picked.
    def start(port, handler_name)
      require 'mime/types'
      require 'rack'

      # Determine handler
      if handler_name.nil?
        handler = preferred_handler
      else
        handler = handler_named(handler_name.to_sym)
        raise UnknownHandlerError.new(handler_name) if handler.nil?
      end

      # Build Rack app
      app = lambda { |env| handle_request(env['PATH_INFO']) }

      # Run Rack app
      port ||= 3000
      handler.run(app, :Port => port, :port => port) do |server|
        trap(:INT) { server.stop }
      end
    end

  private

    def preferred_handler
      return @preferred_handler unless @preferred_handler.nil?

      HANDLER_NAMES.each do |handler_name|
        # Get handler
        @preferred_handler = handler_named(handler_name)

        # Make sure we have one
        break unless @preferred_handler.nil?
      end

      @preferred_handler
    end

    def handler_named(handler_name)
      # Build list of handlers
      @handlers ||= {
        :cgi => {
          :proc => lambda { Rack::Handler::CGI }
        },
        :fastcgi => { # FIXME buggy
          :proc => lambda { Rack::Handler::FastCGI }
        },
        :lsws => { # FIXME test
          :proc => lambda { Rack::Handler::LSWS }
        },
        :mongrel => {
          :proc => lambda { Rack::Handler::Mongrel }
        },
        :scgi => { # FIXME buggy
          :proc => lambda { Rack::Handler::SCGI }
        },
        :webrick => {
          :proc => lambda { Rack::Handler::WEBrick }
        },
        :thin => {
          :proc => lambda { Rack::Handler::Thin },
          :requires => [ 'thin' ]
        },
        :ebb => {
          :proc => lambda { Rack::Handler::Ebb },
          :requires => [ 'ebb' ]
        }
      }

      begin
        # Lookup handler
        handler = @handlers[handler_name]

        # Load requirements
        (handler[:requires] || []).each { |r| require r }

        # Get handler class
        handler[:proc].call
      rescue NameError, LoadError
        nil
      end
    end

    def handle_request(path)
      @mutex.synchronize do
        # Reload site data
        @site.load_data(true)

        # Get paths
        rep_path  = path.cleaned_path
        file_path = @site.config[:output_dir] + path

        # Find rep
        objs = @site.pages + @site.assets
        reps = objs.map { |o| o.reps }.flatten
        rep = reps.find { |r| r.web_path == rep_path }

        if rep.nil?
          # Get list of possible filenames
          if file_path =~ /\/$/
            all_file_paths = @site.config[:index_filenames].map { |f| file_path + f }
          else
            all_file_paths = [ file_path ]
          end
          good_file_path = all_file_paths.find { |f| File.file?(f) }

          # Serve file
          if good_file_path
            serve_file(good_file_path)
          else
            serve_404(path)
          end
        else
          # Serve rep
          serve_rep(rep)
        end
      end
    end

    def h(s)
      ERB::Util.html_escape(s)
    end

    def mime_type_of(path, fallback)
      mime_type = MIME::Types.of(path).first
      mime_type = mime_type.nil? ? fallback : mime_type.simplified
    end

    def serve_404(path)
      # Build response
      [
        404,
        { 'Content-Type' => 'text/html' },
        [ ERB.new(ERROR_404).result(binding) ]
      ]
    end

    def serve_500(path, exception)
      # Build message
      case exception
      when Nanoc::Errors::UnknownLayoutError
        message = "Unknown layout: #{exception.message}"
      when Nanoc::Errors::UnknownFilterError
        message = "Unknown filter: #{exception.message}"
      when Nanoc::Errors::CannotDetermineFilterError
        message = "Cannot determine filter for layout: #{exception.message}"
      when Nanoc::Errors::RecursiveCompilationError
        message = "Recursive call to page content. Page stack:"
      when Nanoc::Errors::NoLongerSupportedError
        message = "No longer supported: #{exception.message}"
      else
        message = "Unknown error: #{exception.message}"
      end

      # Build response
      [
        500,
        { 'Content-Type' => 'text/html' },
        [ ERB.new(ERROR_500).result(binding) ]
      ]
    end

    def serve_file(path)
      # Build response
      [
        200,
        { 'Content-Type' => mime_type_of(path, 'application/octet-stream') },
        [ File.read(path) ]
      ]
    end

    def serve_rep(rep)
      # Recompile rep
      begin
        @site.compiler.run(
          [ rep.respond_to?(:page) ? rep.page : rep.asset ],
          :even_when_not_outdated => @include_outdated
        )
      rescue Exception => exception
        return serve_500(rep.web_path, exception)
      end

      # Build response
      [
        200,
        { 'Content-Type' => mime_type_of(rep.disk_path, 'text/html') },
        [ rep.content(:post) ]
      ]
    end

  end

end
