module Nanoc::CLI

  class CompileCommand < Cri::Command # :nodoc:

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
        },
        # --pages
        {
          :long => 'pages', :short => 'P', :argument => :forbidden,
          :desc => 'only compile pages (no assets)'
        },
        # --assets
        {
          :long => 'assets', :short => 'A', :argument => :forbidden,
          :desc => 'only compile assets (no pages)'
        },
        # --only-outdated
        {
          :long => 'only-outdated', :short => 'o', :argument => :forbidden,
          :desc => 'only compile outdated pages and assets'
        },
      ]
    end

    def run(options, arguments)
      # Make sure we are in a nanoc site directory
      @base.require_site

      # Find object with given path
      if arguments.size == 0
        # Find all pages and/or assets
        if options.has_key?(:pages)
          objs = @base.site.pages
        elsif options.has_key?(:assets)
          objs = @base.site.assets
        else
          objs = nil
        end
      else
        objs = arguments.map do |path|
          # Find object
          path = path.cleaned_path
          obj = @base.site.pages.find { |page| page.path == path }
          obj = @base.site.assets.find { |asset| asset.path == path } if obj.nil?

          # Ensure object
          if obj.nil?
            $stderr.puts "Unknown page or asset: #{path}"
            exit 1
          end

          obj
        end
      end

      # Compile site
      begin
        # Give feedback
        puts "Compiling #{objs.nil? ? 'site' : 'objects'}..."

        # Initialize profiling stuff
        time_before = Time.now
        @filter_times ||= {}
        @times_stack  ||= []
        setup_notifications

        # Parse all/only-outdated options
        if options.has_key?(:all)
          warn "WARNING: The --all option is no longer necessary as nanoc " +
               "2.2 compiles all pages and assets by default. To change this " +
               "behaviour, use the --only-outdated option."
        end
        compile_all = options.has_key?(:'only-outdated') ? false : true

        # Compile
        @base.site.compiler.run(
          objs,
          :even_when_not_outdated => compile_all
        )

        # Find reps
        page_reps  = @base.site.pages.map { |p| p.reps }.flatten
        asset_reps = @base.site.assets.map { |a| a.reps }.flatten
        reps       = page_reps + asset_reps

        # Show skipped reps
        reps.select { |r| !r.compiled? }.each do |rep|
          duration = @rep_times[rep.disk_path]
          Nanoc::CLI::Logger.instance.file(:low, :skip, rep.disk_path, duration)
        end

        # Give general feedback
        puts
        puts "No objects were modified." unless reps.any? { |r| r.modified? }
        puts "#{objs.nil? ? 'Site' : 'Object'} compiled in #{format('%.2f', Time.now - time_before)}s."

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
        $stderr.puts
        $stderr.puts "Warning: profiling information may not be accurate because " +
                     "some objects were not compiled."
      end

      # Print header
      puts
      puts ' ' * max_filter_name_length + ' | count    min    avg    max     tot'
      puts '-' * max_filter_name_length + '-+-----------------------------------'

      @filter_times.to_a.sort_by { |r| r[1] }.each do |row|
        # Extract data
        filter_name, samples = *row

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
      # Get rep
      rep = @base.site.compiler.stack.select { |i| i.is_a?(Nanoc::PageRep) || i.is_a?(Nanoc::AssetRep) }[-1]
      rep_name = rep.nil? ? 'the site' : "#{rep.is_a?(Nanoc::PageRep) ? rep.page.path : rep.asset.path} (rep #{rep.name})"

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
        message = "Error: #{error.message}"
      end

      # Print message
      $stderr.puts
      $stderr.puts "ERROR: An exception occured while compiling #{rep_name}."
      $stderr.puts
      $stderr.puts "If you think this is a bug in nanoc, please do report it at " +
                   "<http://nanoc.stoneship.org/trac/newticket> -- thanks!"
      $stderr.puts
      $stderr.puts 'Message:'
      $stderr.puts '  ' + message
      $stderr.puts
      $stderr.puts 'Compilation stack:'
      @base.site.compiler.stack.reverse.each do |item|
        if item.is_a?(Nanoc::PageRep) # page rep
          $stderr.puts "  - [page]   #{item.page.path} (rep #{item.name})"
        elsif item.is_a?(Nanoc::AssetRep) # asset rep
          $stderr.puts "  - [asset]  #{item.asset.path} (rep #{item.name})"
        else # layout
          $stderr.puts "  - [layout] #{item.path}"
        end
      end
      $stderr.puts
      $stderr.puts 'Backtrace:'
      $stderr.puts error.backtrace.map { |t| '  - ' + t }.join("\n")
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
        [ nil, nil ]
      else
        [ :identical, :low ]
      end

      # Log
      unless action.nil?
        duration = @rep_times[rep.disk_path]
        Nanoc::CLI::Logger.instance.file(level, action, rep.disk_path, duration)
      end
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
