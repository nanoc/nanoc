module Nanoc

  # Nanoc::Compiler is responsible for compiling a site.
  class Compiler

    attr_reader :stack

    # Creates a new compiler for the given site.
    def initialize(site)
      @site = site
    end

    # Compiles (part of) the site and writes out the compiled pages.
    #
    # +page+:: The page (and its dependencies) that should be compiled, or
    #          +nil+ if the entire site should be compiled.
    #
    # +include_outdated+:: +false+ if outdated pages should not be recompiled,
    #                      and +true+ if they should.
    def run(page=nil, include_outdated=false)
      # Load data
      @site.load_data

      # TODO notify when a page is compiled (or not, if it's not modified) (:identical, :updated, :created)

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Initialize
      @stack = []
      pages = (page.nil? ? @site.pages : [ page ])

      # Compile
      pages.each do |current_page|
        # Compile page
        current_page.compile if current_page.outdated? or include_outdated

        # Notify
        yield(current_page) if block_given?
      end
    end

  end
end
