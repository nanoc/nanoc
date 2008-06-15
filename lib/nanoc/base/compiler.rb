module Nanoc

  # Nanoc::Compiler is responsible for compiling a site's page and asset
  # representations.
  class Compiler

    attr_reader :stack

    # Creates a new compiler for the given site.
    def initialize(site)
      @site = site
    end

    # Compiles (part of) the site and writes out the compiled page and asset
    # representations.
    #
    # +page_or_asset+:: The page or asset that should be compiled, along with
    #                   their dependencies, or +nil+ if the entire site should
    #                   be compiled.
    #
    # +include_outdated+:: +false+ if outdated pages and assets should not be
    #                      recompiled, and +true+ if they should.
    def run(page_or_asset=nil, include_outdated=false)
      # Load data
      @site.load_data

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Initialize
      @stack = []

      # Get pages and assets
      unless page_or_asset.nil?
        objects = [ page_or_asset ]
      else
        objects = @site.pages + @site.assets
      end

      # Compile pages and assets
      objects.each do |obj|
        obj.compile if obj.outdated? or include_outdated
        yield obj if block_given?
      end
    end

  end
end
