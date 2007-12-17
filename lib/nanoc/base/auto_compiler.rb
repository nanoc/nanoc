require 'webrick'
require 'mime/types'

module Nanoc

  class AutoCompiler

    def initialize(site)
      # Set site
      @site = site
    end

    def start
      # Create server
      @server = WEBrick::HTTPServer.new(:Port => 2000)
      @server.mount_proc("/") { |request, response| handle_request(request, response) }

      # Start server
      trap('INT') { @server.shutdown }
      @server.start
    end

    def handle_request(request, response)
      # Reload site data
      @site.load_data(:force => true)

      # Serve page or file
      page      = @site.pages.find { |page| page.path == request.path }
      file_path = @site.config[:output_dir] + request.path
      if page.nil?
        if File.exist?(file_path)
          serve_file(file_path, response)
        else
          serve_404(response)
        end
      else
        serve_page(page, response)
      end
    end

    def serve_404(response)
      response.status           = 404
      response['Content-Type']  = 'text/html'
      response.body             = '<p>File not found.</p>'
    end

    def serve_file(path, response)
      response.status           = 200
      response['Content-Type']  = MIME::Types.of(path).first || 'application/octet-stream'
      response.body             = File.read(path)
    end

    def serve_page(page, response)
      # Recompile page
      @site.compiler.run(page)

      response.status           = 200
      response['Content-Type']  = 'text/html'
      response.body             = page.layouted_content
    end

  end

end
