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
	</head>
	<body>
		<h1>404 File Not Found</h1>
		<p>The file you requested, <i><%=h path %></i>, was not found on this server.</p>
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

      @mutex.synchronize do
        # Reload site data
        @site.load_data(true)

        # Get file path
        path = env['PATH_INFO']
        file_path = @site.config[:output_dir] + path

        # Find rep
        reps = @site.items.map { |i| i.reps }.flatten
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
    rescue StandardError, LoadError, SyntaxError => e
      # Add compilation stack to env
      env['nanoc.stack'] = []
      @site.compiler.stack.reverse.each do |obj|
        if obj.is_a?(Nanoc3::ItemRep) # item rep
          env['nanoc.stack'] << "[item] #{obj.item.identifier} (rep #{obj.name})"
        else # layout
          env['nanoc.stack'] << "[layout] #{obj.identifier}"
        end
      end

      # Re-raise error
      raise e
    end

  private

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
      @site.compiler.run([ rep.item ], :force => true)

      # Build response
      [
        200,
        { 'Content-Type' => mime_type_of(rep.raw_path, 'text/html') },
        [ rep.content_at_snapshot(:post) ]
      ]
    end

  end

end
