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

      # Give feedback
      log(:high, "Compiling #{page.nil? ? 'site' : 'page'}...")
      time_before = Time.now

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Compile
      @stack = []
      pages = (page.nil? ? @site.pages : [ page ])
      pages.each do |current_page|
        begin
          current_page.compile if current_page.outdated? or include_outdated
        rescue Exception => exception
          handle_exception(exception, current_page, !page.nil?)
        end
      end

      # Give feedback
      log(:high, "No pages were modified.") unless pages.any? { |p| p.modified? }
      log(:high, "#{page.nil? ? 'Site' : 'Page'} compiled in #{format('%.2f', Time.now - time_before)}s.")
    end

  private

    def handle_exception(exception, page, single_page)
      raise exception if single_page

      log(:high, "ERROR: An exception occured while compiling page #{page.path}.", $stderr)
      log(:high, "", $stderr)
      log(:high, "If you think this is a bug in nanoc, please do report it at", $stderr)
      log(:high, "<http://nanoc.stoneship.org/trac/newticket> -- thanks!", $stderr)
      log(:high, "", $stderr)
      log(:high, 'Message:', $stderr)
      log(:high, '  ' + exception.message, $stderr)
      log(:high, 'Backtrace:', $stderr)
      log(:high, exception.backtrace.map { |t| '  - ' + t }.join("\n"), $stderr)

      exit(1)
    end

  end
end
