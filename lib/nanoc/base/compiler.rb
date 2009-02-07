module Nanoc

  # Nanoc::Compiler is responsible for compiling a site's page and asset
  # representations.
  class Compiler

    attr_reader :stack

    # Creates a new compiler for the given site.
    def initialize(site)
      @site  = site
      @stack = []
    end

    # Compiles (part of) the site and writes out the compiled page and asset
    # representations.
    #
    # +obj+:: The page or asset that should be compiled, along with their
    #         dependencies, or +nil+ if the entire site should be compiled.
    #
    # This method also accepts a few parameters:
    #
    # +:force+:: true if the rep should be compiled even if
    #                             it is not outdated, false if not. Defaults
    #                             to false.
    def run(objects=nil, params={})
      # Parse params
      force = params[:force] || false

      # Load data
      @site.load_data

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Initialize
      @stack = []

      # Get pages and asset reps
      objects = @site.pages + @site.assets if objects.nil?
      reps = objects.map { |o| o.reps }.flatten

      # Compile everything
      reps.each do |rep|
        rep.compile(force)
      end
    end

  end

end
