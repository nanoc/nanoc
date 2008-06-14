module Nanoc

  # Nanoc::Compiler is responsible for compiling a site.
  class Compiler

    attr_reader :stack

    # Creates a new compiler for the given site.
    def initialize(site)
      @site = site
    end

    # TODO fix documentation
    # Compiles (part of) the site and writes out the compiled pages.
    #
    # +page+:: The page (and its dependencies) that should be compiled, or
    #          +nil+ if the entire site should be compiled.
    #
    # +include_outdated+:: +false+ if outdated pages should not be recompiled,
    #                      and +true+ if they should.
    def run(page_or_asset=nil, include_outdated=false)
      # Load data
      @site.load_data

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Initialize
      @stack = []

      # Get pages and assets
      pages  = (page_or_asset && page_or_asset.is_a?(Page)  ? [ page_or_asset ] : @site.pages )
      assets = (page_or_asset && page_or_asset.is_a?(Asset) ? [ page_or_asset ] : @site.assets)

      # Compile pages and assets
      compile_objects(pages,  include_outdated) { |p| yield(p) if block_given? }
      compile_objects(assets, include_outdated) { |a| yield(a) if block_given? }
    end

    def compile_objects(objects, include_outdated)
      objects.each { |obj| obj.compile if obj.outdated? or include_outdated }
    end

  end
end
