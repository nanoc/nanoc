module Nanoc::CLI

  class CompileCommand < Command # :nodoc:

    def name
      'compile'
    end

    def aliases
      []
    end

    def short_desc
      'compile pages of this site'
    end

    def long_desc
      'Compile all pages of the current site. If a path is given, only ' +
      'the page with the given path will be compiled. Additionally, only ' +
      'pages that are outdated will be compiled, unless specified ' +
      'otherwise with the -a option.'
    end

    def usage
      "nanoc compile [options] [path]"
    end

    def option_definitions
      [
        # --all
        {
          :long => 'all', :short => 'a', :argument => :forbidden,
          :desc => 'compile all pages, even those that aren\'t outdated'
        }
      ]
    end

    def run(options, arguments)
      # Check arguments
      if arguments.size > 1
        puts "usage: #{usage}"
        exit 1
      end

      # Make sure we are in a nanoc site directory
      @base.require_site

      # Find page with given path
      if arguments[0].nil?
        page = nil
      else
        path = arguments[0].cleaned_path
        page = @base.site.pages.find { |page| page.path == path }
        if page.nil?
          puts "Unknown page: #{path}"
          exit 1
        end
      end

      # Compile site
      begin
        # Give feedback
        puts "Compiling #{page.nil? ? 'site' : 'page'}..."
        time_before = Time.now

        # Compile
        @base.site.compiler.add_observer(self)
        @base.site.compiler.run(page, options.has_key?(:all))

        # Give feedback
        puts "No pages were modified." unless @base.site.pages.any? { |p| p.reps.any? { |r| r.modified? } }
        puts "#{page.nil? ? 'Site' : 'Page'} compiled in #{format('%.2f', Time.now - time_before)}s."
      rescue Exception => e
        # Get page rep
        page_rep = @base.site.compiler.stack.select { |i| i.is_a?(Nanoc::PageRep) }[-1]
        page_rep_name = page_rep.nil? ? 'the site' : "#{page_rep.page.path} (rep #{page_rep.name})"

        # Build message
        case e
        when Nanoc::Errors::UnknownLayoutError
          message = "Unknown layout: #{e.message}"
        when Nanoc::Errors::UnknownFilterError
          message = "Unknown filter: #{e.message}"
        when Nanoc::Errors::CannotDetermineFilterError
          message = "Cannot determine filter for layout: #{e.message}"
        when Nanoc::Errors::RecursiveCompilationError
          message = "Recursive call to page content."
        when Nanoc::Errors::NoLongerSupportedError
          message = "No longer supported: #{e.message}"
        else
          message = "Unknown error: #{e.message}"
        end

        # Print message
        puts
        puts "ERROR: An exception occured while compiling #{page_rep_name}."
        puts
        puts "If you think this is a bug in nanoc, please do report it at"
        puts "<http://nanoc.stoneship.org/trac/newticket> -- thanks!"
        puts
        puts 'Message:'
        puts '  ' + message
        puts
        puts 'Page compilation stack:'
        @base.site.compiler.stack.reverse.each do |item|
          if item.is_a?(Nanoc::PageRep) # page rep
            puts "  - [page]   #{item.page.path} (rep #{item.name})"
          else # layout
            puts "  - [layout] #{item.path}"
          end
        end
        puts
        puts 'Backtrace:'
        puts e.backtrace.map { |t| '  - ' + t }.join("\n")
      end
    ensure
      @base.site.compiler.delete_observer(self)
    end

    def update(rep, event, outdated_included)
      # Profile compilation
      @times ||= {}
      if event == :compile_start
        @times[rep.disk_path] = Time.now
      elsif event == :compile_end
        @times[rep.disk_path] = Time.now - @times[rep.disk_path]
      end

      # Only print at end of compilation
      return unless event == :compile_end

      # Get action and level
      action, level = *if rep.created?
        [ :create, :high ]
      elsif rep.modified?
        [ :update, :high ]
      elsif !rep.outdated? && !outdated_included
        [ :skip, :low ]
      else
        [ :identical, :low ]
      end

      # Log
      duration = @times[rep.disk_path]
      Nanoc::CLI::Logger.instance.file(level, action, rep.disk_path, duration)
    end

  end

end
