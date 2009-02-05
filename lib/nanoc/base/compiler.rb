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
    # +:even_when_not_outdated+:: true if the rep should be compiled even if
    #                             it is not outdated, false if not. Defaults
    #                             to false.
    #
    # +:from_scratch+:: true if all compilation stages (for page reps:
    #                   pre-filter, layout, post-filter; for asset reps:
    #                   filter) should be performed again even if they have
    #                   already been performed, false otherwise. Defaults to
    #                   false.
    def run(objects=nil, params={})
      # Parse params
      even_when_not_outdated  = params[:even_when_not_outdated] || false
      from_scratch            = params[:from_scratch]           || false

      # Load data
      @site.load_data

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Initialize
      @stack = []

      # Get pages and asset reps
      objects = @site.pages + @site.assets if objects.nil?
      reps = objects.map { |o| o.reps }.flatten

      # Set up dependency tracker
      dependency_tracker = Nanoc::DependencyTracker.new
      dependency_tracker.load_state
      dependency_tracker.mark_outdated_dependencies(reps)
      dependency_tracker.start

      # Compile everything
      reps.each do |rep|
        rep.compile(even_when_not_outdated, from_scratch)
      end

      # Store dependencies
      dependency_tracker.stop
      dependency_tracker.store_state
    end

  end

end
