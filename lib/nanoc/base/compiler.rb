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
      @include_outdated = include_outdated

      # Get pages and assets
      unless page_or_asset.nil?
        objects = [ page_or_asset ]
      else
        objects = @site.pages + @site.assets
      end
      reps = objects.map { |o| o.reps }.flatten

      # Compile everything
      reps.each do |rep|
        if rep.outdated? or include_outdated
          rep.compile
        else
          Nanoc::NotificationCenter.post(:compilation_started, rep)
          Nanoc::NotificationCenter.post(:compilation_ended,   rep)
        end
      end
    end

  end
end
