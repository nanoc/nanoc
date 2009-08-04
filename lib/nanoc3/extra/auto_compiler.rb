# encoding: utf-8

module Nanoc3::Extra

  # Nanoc3::Extra::AutoCompiler is a web server that will automatically compile
  # items as they are requested. It also serves static files such as
  # stylesheets and images.
  class AutoCompiler

    # Creates a new autocompiler for the given site.
    def initialize(site)
      require 'rack'
      require 'mime/types'

      # Set site
      @site = site

      # Create mutex to prevent parallel requests
      @mutex = Mutex.new
    end

    def call(env)
      @mutex.synchronize do
        # Reload site data
        @site.load_data(true)

        # Find rep
        path = env['PATH_INFO']
        reps = @site.items.map { |i| i.reps }.flatten
        rep = reps.find { |r| r.path == path }

        if rep
          serve(rep)
        else
          # Get paths by appending index filenames
          if path =~ /\/$/
            possible_paths = @site.config[:index_filenames].map { |f| path + f }
          else
            possible_paths = [ path ]
          end

          # Find matching file
          modified_path = possible_paths.find { |f| File.file?(@site.config[:output_dir] + f) }
          modified_path ||= path

          # Serve using Rack::File
          file_server.call(env.merge('PATH_INFO' => modified_path))
        end
      end
    rescue StandardError, ScriptError => e
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

    def mime_type_of(path, fallback)
      mime_type = MIME::Types.of(path).first
      mime_type = mime_type.nil? ? fallback : mime_type.simplified
    end

    def file_server
      @file_server ||= ::Rack::File.new(@site.config[:output_dir])
    end

    def serve(rep)
      # Recompile rep
      @site.compiler.run(rep.item, :force => true)

      # Build response
      [
        200,
        { 'Content-Type' => mime_type_of(rep.raw_path, 'text/html') },
        [ rep.content_at_snapshot(:last) ]
      ]
    end

  end

end
