module Nanoc
  class Compiler

    attr_reader :stack

    def initialize(site)
      @site = site
    end

    def run(page=nil)
      # Give feedback
      puts "Compiling #{page.nil? ? 'site' : 'page'}..." unless $quiet
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
      puts "#{page.nil? ? 'Site' : 'Pages'} compiled in #{format('%.2f', Time.now - time_before)}s." unless $quiet
    end

    def handle_exception(exception, page, single_page)
      if single_page
        raise exception
        return
      end

      unless $quiet or exception.class == SystemExit
        $stderr.puts "ERROR: An exception occured while compiling page #{page.path}."
        $stderr.puts
        $stderr.puts "If you think this is a bug in nanoc, please do report it at"
        $stderr.puts "<http://nanoc.stoneship.org/trac/newticket> -- thanks!"
        $stderr.puts
        $stderr.puts 'Message:'
        $stderr.puts '  ' + exception.message
        $stderr.puts 'Backtrace:'
        $stderr.puts exception.backtrace.map { |t| '  - ' + t }.join("\n")
      end
      exit(1)
    end

  end
end
