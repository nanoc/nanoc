module Nanoc

  # Nanoc::Compiler is responsible for compiling a site.
  class Compiler

    attr_reader :stack

    # Creates a new compiler for the given site.
    def initialize(site)
      @site = site
    end

    # Compiles the site. When the +page+ argument is nil, compiles the entire
    # site; compiles only the specified page (and dependencies) otherwise.
    def run(page=nil, all=false)
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
          current_page.compile if current_page.outdated? or all
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
