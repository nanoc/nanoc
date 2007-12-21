module Nanoc
  class Compiler

    attr_reader :stack

    def initialize(site)
      @site = site
    end

    def run(page=nil)
      # Give feedback
      log(:high, "Compiling #{page.nil? ? 'site' : 'page'}...")
      time_before = Time.now

      # Get the data we need
      @site.load_data
      eval(@site.code, $nanoc_binding)

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Compile
      @stack = []
      (page.nil? ? @site.pages : [ page ]).each do |current_page|
        begin
          current_page.compile
        rescue => exception
          handle_exception(exception, current_page, !page.nil?)
        end
      end

      # Give feedback
      log(:high, "#{page.nil? ? 'Site' : 'Pages'} compiled in #{format('%.2f', Time.now - time_before)}s.")
    end

    def handle_exception(exception, page, single_page)
      if single_page
        raise exception
        return
      end

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
