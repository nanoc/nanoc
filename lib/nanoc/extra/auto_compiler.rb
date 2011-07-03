# encoding: utf-8

module Nanoc::Extra

  # A web server that will automatically compile items as they are requested.
  # It also serves static files such as stylesheets and images.
  class AutoCompiler

    # @return [Nanoc::Site] The site this autocompiler belongs to
    attr_reader :site

    # Creates a new autocompiler for the given site.
    #
    # @param [String] site_path The path to the site to autocompile
    def initialize(site_path)
      require 'rack'
      require 'mime/types'

      # Set site
      @site_path = site_path

      # Create mutex to prevent parallel requests
      require 'thread'
      @mutex = Mutex.new
    end

    # Calls the autocompiler. The behaviour of this method is defined by the
    # [Rack specification](http://rack.rubyforge.org/doc/files/SPEC.html).
    #
    # @param [Hash] env The environment, as defined by the Rack specification
    #
    # @return [Array] An array containing the status, the headers, and the
    #   body, as defined by the Rack specification
    def call(env)
      @mutex.synchronize do
        # Start with a new site
        build_site

        # Find rep
        path = Rack::Utils::unescape(env['PATH_INFO'])
        reps = site.items.map { |i| i.reps }.flatten
        rep = reps.find do |r|
          r.path == path ||
            r.raw_path == site.config[:output_dir] + path
        end

        # Recompile
        site.compile if rep

        # Get paths by appending index filenames
        if path =~ /\/$/
          possible_paths = site.config[:index_filenames].map { |f| path + f }
        else
          possible_paths = [ path ]
        end

        # Find matching file
        modified_path = possible_paths.find { |f| File.file?(site.config[:output_dir] + f) }
        modified_path ||= path

        # Serve using Rack::File
        puts "*** serving file #{modified_path}"
        res = file_server.call(env.merge('PATH_INFO' => modified_path))
        puts "*** done serving file #{modified_path}"
        res
      end
    rescue StandardError, ScriptError => e
      # Add compilation stack to env
      env['nanoc.stack'] = []
      stack.reverse.each do |obj|
        if obj.is_a?(Nanoc::ItemRep) # item rep
          env['nanoc.stack'] << "[item] #{obj.item.identifier} (rep #{obj.name})"
        else # layout
          env['nanoc.stack'] << "[layout] #{obj.identifier}"
        end
      end

      # Re-raise error
      raise e
    end

  private

    def build_site
      @site = Nanoc::Site.new(@site_path)
    end

    def mime_type_of(path, fallback)
      mime_type = MIME::Types.of(path).first
      mime_type = mime_type.nil? ? fallback : mime_type.simplified
    end

    def file_server
      @file_server ||= ::Rack::File.new(site.config[:output_dir])
    end

    def stack
      site.compiler.stack
    end

  end

end
