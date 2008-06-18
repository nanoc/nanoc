module Nanoc

  # Nanoc::Compiler is responsible for compiling a site's page and asset
  # representations.
  #
  # A compiler can be observed. Events will be notified through the 'update'
  # method (as specified by Observable) with the page representation as its
  # first argument, followed by a symbol describing the event (described in
  # the Nanoc::PageRep and Nanoc::AssetRep documentation), and followed by a
  # boolean variable indicating whether outdated representations were compiled
  # or not.
  class Compiler

    attr_reader :stack

    # Creates a new compiler for the given site.
    def initialize(site)
      @site = site
    end

    # Compiles (part of) the site and writes out the compiled page and asset
    # representations.
    #
    # +obj+:: The page or asset that should be compiled, along with their
    #         dependencies, or +nil+ if the entire site should be compiled.
    #
    # This method also accepts a few parameters:
    #
    # +:also_layout+:: true if the page rep should also be laid out and
    #                  post-filtered, false if the page rep should only be
    #                  pre-filtered. Only applicable to page reps, and not to
    #                  asset reps. Defaults to true.
    #
    # +:even_when_not_outdated+:: true if the rep should be compiled even if it is
    #                         not outdated, false if not. Defaults to false.
    #
    # +:from_scratch+:: true if all compilation stages (for page reps:
    #                   pre-filter, layout, post-filter; for asset reps:
    #                   filter) should be performed again even if they have
    #                   already been performed, false otherwise. Defaults to
    #                   false.
    def run(obj=nil, params={})
      # Parse params
      also_layout         = params[:also_layout]        || true
      even_when_not_outdated  = params[:even_when_not_outdated] || false
      from_scratch        = params[:from_scratch]       || false

      # Load data
      @site.load_data

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Initialize
      @stack = []

      # Get pages and asset reps
      objects = obj.nil? ? @site.pages + @site.assets : [ obj ]
      reps = objects.map { |o| o.reps }.flatten

      # Compile everything
      reps.each do |rep|
        if rep.is_a?(Nanoc::PageRep)
          rep.compile(also_layout, even_when_not_outdated, from_scratch)
        else
          rep.compile(even_when_not_outdated, from_scratch)
        end
      end
    end

  end
end
