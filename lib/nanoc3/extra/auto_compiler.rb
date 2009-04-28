module Nanoc3::Extra

  # Nanoc3::Extra::AutoCompiler is a web server that will automatically compile
  # items as they are requested. It also serves static files such as
  # stylesheets and images.
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
		<p>An error occurred while compiling the item you requested, <i><%=h path %></i>.</p>
		<p>If you think this is a bug in nanoc, please do <a href="http://projects.stoneship.org/trac/nanoc/newticket">report it</a>&mdash;thanks!</p>
		<p>Message:</p>
		<blockquote><p><%=h message %></p></blockquote>
		<p>Item compilation stack:</p>
		<ol>
<% @site.compiler.stack.reverse.each do |obj| %>
<% if item.is_a?(Nanoc3::ItemRep) %>
			<li><strong>Item</strong> <%= obj.item.identifier %> (rep <%= obj.name %>)</li>
<% else # layout %>
			<li><strong>Layout</strong> <%= obj.identifier %></li>
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
    def initialize(site)
      # Set site
      @site = site

      # Create mutex to prevent parallel requests
      @mutex = Mutex.new
    end

    def call(env)
      require 'mime/types'

      handle_request(env['PATH_INFO'])
    rescue Exception => exception
      return serve_500(nil, exception)
    end

  private

    def handle_request(path)
      @mutex.synchronize do
        # Reload site data
        @site.load_data(true)

        # Build reps for each item
        # FIXME ugly
        @site.compiler.instance_eval do
          load_rules
          @site.items.each do |item|
            item.reps.clear
            build_reps_for(item)
            item.reps.each { |r| map_rep(r) }
          end
        end

        # Get file path
        file_path = @site.config[:output_dir] + path

        # Find rep
        reps = @site.items.map { |o| o.reps }.flatten
        rep = reps.find { |r| r.path == path }

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
      when Nanoc3::Errors::UnknownLayoutError
        message = "Unknown layout: #{exception.message}"
      when Nanoc3::Errors::UnknownFilterError
        message = "Unknown filter: #{exception.message}"
      when Nanoc3::Errors::CannotDetermineFilterError
        message = "Cannot determine filter for layout: #{exception.message}"
      when Nanoc3::Errors::RecursiveCompilationError
        message = "Recursive call to item content. Item stack:"
      when Nanoc3::Errors::NoLongerSupportedError
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
        [ File.open(path, 'rb') { |io| io.read } ]
      ]
    end

    def serve_rep(rep)
      # Recompile rep
      begin
        @site.compiler.run([ rep.item ], :force => true)
      rescue Exception => exception
        return serve_500(rep.path, exception)
      end

      # Build response
      [
        200,
        { 'Content-Type' => mime_type_of(rep.raw_path, 'text/html') },
        [ rep.content_at_snapshot(:post) ]
      ]
    end

  end

end
