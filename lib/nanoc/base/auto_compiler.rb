require 'webrick'

module Nanoc

  class AutoCompiler

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
		<blockquote><p><%=h exception.message %></p></blockquote>
		<p>Backtrace:</p>
		<ol>
<% exception.backtrace.each do |line| %>
			<li><%= line %></li>
<% end %>
		</ol>
	</body>
</html>
END

    def initialize(site)
      # Set site
      @site = site
    end

    def start(port)
      nanoc_require(
        'mime/types',
        "'mime/types' is required to autocompile sites. You may want to " +
        "install the mime-types gem by running 'gem install mime-types'."
      )

      # Create server
      @server = WEBrick::HTTPServer.new(:Port => port || 3000)
      @server.mount_proc("/") { |request, response| handle_request(request, response) }

      # Start server
      trap('INT') { @server.shutdown }
      @server.start
    end

    def handle_request(request, response)
      # Reload site data
      @site.load_data(true)

      # Get page or file
      page      = @site.pages.find { |page| [ request.path, "/#{request.path}/".gsub(/^\/+|\/+$/, '/') ].include?(page.path) }
      file_path = @site.config[:output_dir] + request.path

      if page.nil?
        # Serve file
        if File.file?(file_path)
          serve_file(file_path, response)
        else
          serve_404(request.path, response)
        end
      else
        # Serve page
        serve_page(page, response)
      end
    end

    def h(s)
      ERB::Util.html_escape(s)
    end

    def serve_404(path, response)
      response.status           = 404
      response['Content-Type']  = 'text/html'
      response.body             = ERB.new(ERROR_404).result(binding)
    end

    def serve_500(path, exception, response)
      response.status           = 500
      response['Content-Type']  = 'text/html'
      response.body             = ERB.new(ERROR_500).result(binding)
    end

    def serve_file(path, response)
      response.status           = 200
      response['Content-Type']  = MIME::Types.of(path).first || 'application/octet-stream'
      response.body             = File.read(path)
    end

    def serve_page(page, response)
      # Recompile page
      begin
        @site.compiler.run(page)
      rescue => exception
        serve_500(page.path, exception, response)
        return
      end

      # Determine most likely MIME type
      mime_type = MIME::Types.of(page.path).first
      mime_type = mime_type.nil? ? 'text/html' : mime_type.simplified

      response.status           = 200
      response['Content-Type']  = mime_type
      response.body             = page.layouted_content
    end

  end

end
