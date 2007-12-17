module Nanoc
  class Compiler

    attr_reader :stack

    def initialize(site)
      @site = site
    end

    def run(page=nil)
      # Require all Ruby source files in lib/
      eval(@site.code, $nanoc_binding)

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Give feedback
      puts "Compiling #{page.nil? ? 'site' : 'page'}..." unless $quiet
      time_before = Time.now

      # Compile
      @stack = []
      (page.nil? ? @site.pages : [ page ]).each { |p| p.compile }

      # Give feedback
      puts "#{page.nil? ? 'Site' : 'Pages'} compiled in #{format('%.2f', Time.now - time_before)}s." unless $quiet
    rescue => exception
      if page.nil?
        unless $quiet or exception.class == SystemExit
          $stderr.puts "ERROR: Exception occured while compiling #{page.path}:\n"
          $stderr.puts '  ' + exception.message
          $stderr.puts 'Backtrace:'
          $stderr.puts exception.backtrace.map { |t| '  - ' + t }.join("\n")
        end
        exit(1)
      else
        raise exception
      end
    end

  end
end
