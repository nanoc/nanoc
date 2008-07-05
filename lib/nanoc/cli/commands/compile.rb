module Nanoc::CLI

  class CompileCommand < Command # :nodoc:

    def name
      'compile'
    end

    def aliases
      []
    end

    def short_desc
      'compile pages and assets of this site'
    end

    def long_desc
      'Compile all pages and all assets of the current site. If a path is ' +
      'given, only the page or asset with the given path will be compiled. ' +
      'Additionally, only pages and assets that are outdated will be ' +
      'compiled, unless specified otherwise with the -a option.'
    end

    def usage
      "nanoc compile [options] [path]"
    end

    def option_definitions
      [
        # --all
        {
          :long => 'all', :short => 'a', :argument => :forbidden,
          :desc => 'compile all pages and assets, even those that aren\'t outdated'
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
        obj = nil
      else
        path = arguments[0].cleaned_path
        obj = @base.site.pages.find { |page| page.path == path }
        obj = @base.site.assets.find { |asset| asset.path == path } if obj.nil?
        if obj.nil?
          puts "Unknown page: #{path}"
          exit 1
        end
      end

      # Compile site
      begin
        # Give feedback
        puts "Compiling #{obj.nil? ? 'site' : 'page/asset'}..."

        # Initialize profiling stuff
        time_before = Time.now
        @filter_times ||= {}
        @times_stack  ||= []
        setup_notifications

        # Compile
        @base.site.compiler.run(
          obj.nil? ? nil : [ obj ],
          :even_when_not_outdated => options.has_key?(:all)
        )

        # Find reps
        page_reps  = @base.site.pages.map { |p| p.reps }.flatten
        asset_reps = @base.site.assets.map { |a| a.reps }.flatten
        reps       = page_reps + asset_reps

        # Give general feedback
        puts
        puts "No pages were modified." unless reps.any? { |r| r.modified? }
        puts "#{obj.nil? ? 'Site' : 'Page'} compiled in #{format('%.2f', Time.now - time_before)}s."

        if options.has_key?(:verbose)
          print_state_feedback(reps)
          print_profiling_feedback(reps)
        end
      rescue Interrupt => e
        exit
      rescue Exception => e
        print_error(e)
      end
    end

  private

    def setup_notifications
      Nanoc::NotificationCenter.on(:compilation_started) do |rep|
        rep_compilation_started(rep)
      end
      Nanoc::NotificationCenter.on(:compilation_ended) do |rep|
        rep_compilation_ended(rep)
      end
      Nanoc::NotificationCenter.on(:filtering_started) do |rep, filter_name|
        rep_filtering_started(rep, filter_name)
      end
      Nanoc::NotificationCenter.on(:filtering_ended) do |rep, filter_name|
        rep_filtering_ended(rep, filter_name)
      end
    end

    def print_state_feedback(reps)
      # Categorise reps
      rest            = reps
      created, rest   = *rest.partition { |r| r.created? }
      modified, rest  = *rest.partition { |r| r.modified? }
      skipped, rest   = *rest.partition { |r| !r.compiled? }
      identical       = rest

      # Print
      puts
      puts format('  %4d  created',   created.size)
      puts format('  %4d  modified',  modified.size)
      puts format('  %4d  skipped',   skipped.size)
      puts format('  %4d  identical', identical.size)
    end

    def print_profiling_feedback(reps)
      # Get max filter length
      max_filter_name_length = @filter_times.keys.map { |k| k.to_s.size }.max
      return if max_filter_name_length.nil?

      # Print warning if necessary
      if reps.any? { |r| !r.compiled? }
        puts
        puts "Warning: profiling information may not be accurate because " +
             "some pages were not compiled."
      end

      # Print header
      puts
      puts ' ' * max_filter_name_length + ' | count    min    avg    max     tot'
      puts '-' * max_filter_name_length + '-+-----------------------------------'

      @filter_times.each_pair do |filter_name, samples|
        # Calculate stats
        count = samples.size
        min   = samples.min
        tot   = samples.inject { |memo, i| memo + i}
        avg   = tot/count
        max   = samples.max

        # Format stats
        count = format('%4d',   count)
        min   = format('%4.2f', min)
        avg   = format('%4.2f', avg)
        max   = format('%4.2f', max)
        tot   = format('%5.2f', tot)

        # Output stats
        filter_name = format("%#{max_filter_name_length}s", filter_name)
        puts "#{filter_name} |  #{count}  #{min}s  #{avg}s  #{max}s  #{tot}s"
      end
    end

    def print_error(error)
      # Get page rep
      page_rep = @base.site.compiler.stack.select { |i| i.is_a?(Nanoc::PageRep) }[-1]
      page_rep_name = page_rep.nil? ? 'the site' : "#{page_rep.page.path} (rep #{page_rep.name})"

      # Build message
      case error
      when Nanoc::Errors::UnknownLayoutError
        message = "Unknown layout: #{error.message}"
      when Nanoc::Errors::UnknownFilterError
        message = "Unknown filter: #{error.message}"
      when Nanoc::Errors::CannotDetermineFilterError
        message = "Cannot determine filter for layout: #{error.message}"
      when Nanoc::Errors::RecursiveCompilationError
        message = "Recursive call to page content."
      when Nanoc::Errors::NoLongerSupportedError
        message = "No longer supported: #{error.message}"
      else
        message = "Unknown error: #{error.message}"
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
        elsif item.is_a?(Nanoc::AssetRep) # asset rep
          puts "  - [asset]  #{item.asset.path} (rep #{item.name})"
        else # layout
          puts "  - [layout] #{item.path}"
        end
      end
      puts
      puts 'Backtrace:'
      puts error.backtrace.map { |t| '  - ' + t }.join("\n")
    end

    def rep_compilation_started(rep)
      # Profile compilation
      @rep_times ||= {}
      @rep_times[rep.disk_path] = Time.now
    end

    def rep_compilation_ended(rep)
      # Profile compilation
      @rep_times ||= {}
      @rep_times[rep.disk_path] = Time.now - @rep_times[rep.disk_path]

      # Skip if not outputted
      return if rep.attribute_named(:skip_output)

      # Get action and level
      action, level = *if rep.created?
        [ :create, :high ]
      elsif rep.modified?
        [ :update, :high ]
      elsif !rep.compiled?
        [ :skip, :low ]
      else
        [ :identical, :low ]
      end

      # Log
      duration = @rep_times[rep.disk_path]
      Nanoc::CLI::Logger.instance.file(level, action, rep.disk_path, duration)
    end

    def rep_filtering_started(rep, filter_name)
      @times_stack.push(Time.now)
    end

    def rep_filtering_ended(rep, filter_name)
      # Get last time
      time_start = @times_stack.pop

      # Update times
      @filter_times[filter_name.to_sym] ||= []
      @filter_times[filter_name.to_sym] << Time.now - time_start
    end

  end

end
