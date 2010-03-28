# encoding: utf-8

module Nanoc3::CLI::Commands

  class Compile < Cri::Command

    def name
      'compile'
    end

    def aliases
      []
    end

    def short_desc
      'compile items of this site'
    end

    def long_desc
      'Compile all items of the current site. If an identifier is given, ' +
      'only the item with the given identifier will be compiled. ' +
      "\n\n" +
      'By default, only item that are outdated will be compiled. This can ' +
      'speed up the compilation process quite a bit, but items that include ' +
      'content from other items may have to be recompiled manually. In ' +
      'order to compile items even when they are outdated, use the --force option.'
    end

    def usage
      "nanoc3 compile [options] [identifier]"
    end

    def option_definitions
      [
        # --all
        {
          :long => 'all', :short => 'a', :argument => :forbidden,
          :desc => 'alias for --force (DEPRECATED)'
        },
        # --force
        {
          :long => 'force', :short => 'f', :argument => :forbidden,
          :desc => 'compile items even when they are not outdated'
        }
      ]
    end

    def run(options, arguments)
      # Make sure we are in a nanoc site directory
      puts "Loading site data..."
      @base.require_site
      @base.site.load_data

      # Check presence of --all option
      if options.has_key?(:all)
        $stderr.puts "Warning: the --all option is deprecated; please use --force instead."
      end

      # Find item(s) to compile
      if arguments.size == 0
        item = nil
      elsif arguments.size == 1
        # Find item
        identifier = arguments[0].cleaned_identifier
        item = @base.site.items.find { |item| item.identifier == identifier }

        # Ensure item
        if item.nil?
          $stderr.puts "Unknown item: #{identifier}"
          exit 1
        end
      end

      # Give feedback
      puts "Compiling #{item.nil? ? 'site' : 'item'}..."

      # Initialize profiling stuff
      time_before = Time.now
      @filter_times ||= {}
      @times_stack  ||= []
      setup_notifications

      # Compile
      @base.site.compiler.run(
        item,
        :force => options.has_key?(:all) || options.has_key?(:force)
      )

      # Find reps
      reps = @base.site.items.map  { |i| i.reps }.flatten

      # Show skipped reps
      reps.select { |r| !r.compiled? }.each do |rep|
        next if rep.raw_path.nil?
        duration = @rep_times[rep.raw_path]
        Nanoc3::CLI::Logger.instance.file(:high, :skip, rep.raw_path, duration)
      end

      # Show diff
      write_diff_for(reps)

      # Give general feedback
      puts
      puts "No items were modified." unless reps.any? { |r| r.modified? }
      puts "#{item.nil? ? 'Site' : 'Item'} compiled in #{format('%.2f', Time.now - time_before)}s."

      if options.has_key?(:verbose)
        print_state_feedback(reps)
        print_profiling_feedback(reps)
      end
    end

  private

    def setup_notifications
      Nanoc3::NotificationCenter.on(:compilation_started) do |rep|
        rep_compilation_started(rep)
      end
      Nanoc3::NotificationCenter.on(:compilation_ended) do |rep|
        rep_compilation_ended(rep)
      end
      Nanoc3::NotificationCenter.on(:filtering_started) do |rep, filter_name|
        rep_filtering_started(rep, filter_name)
      end
      Nanoc3::NotificationCenter.on(:filtering_ended) do |rep, filter_name|
        rep_filtering_ended(rep, filter_name)
      end
    end

    def write_diff_for(reps)
      # Delete diff
      FileUtils.rm('output.diff') if File.file?('output.diff')

      # Don’t generate diffs when diffs are disabled
      return if !@base.site.config[:enable_output_diff]

      # Generate diff
      full_diff = ''
      reps.each do |rep|
        diff = rep.diff
        next if diff.nil?

        # Fix header
        diff.sub!(/^--- .*/,    '--- ' + rep.raw_path)
        diff.sub!(/^\+\+\+ .*/, '+++ ' + rep.raw_path)

        # Add
        full_diff << diff
      end

      # Write
      File.open('output.diff', 'w') { |io| io.write(full_diff) }
    end

    def print_state_feedback(reps)
      # Categorise reps
      rest              = reps
      created, rest     = *rest.partition { |r| r.created? }
      modified, rest    = *rest.partition { |r| r.modified? }
      skipped, rest     = *rest.partition { |r| !r.compiled? }
      not_written, rest = *rest.partition { |r| r.compiled? && !r.written? }
      identical         = rest

      # Print
      puts
      puts format('  %4d  created',     created.size)
      puts format('  %4d  modified',    modified.size)
      puts format('  %4d  skipped',     skipped.size)
      puts format('  %4d  not written', not_written.size)
      puts format('  %4d  identical',   identical.size)
    end

    def print_profiling_feedback(reps)
      # Get max filter length
      max_filter_name_length = @filter_times.keys.map { |k| k.to_s.size }.max
      return if max_filter_name_length.nil?

      # Print warning if necessary
      if reps.any? { |r| !r.compiled? }
        $stderr.puts
        $stderr.puts "Warning: profiling information may not be accurate because " +
                     "some items were not compiled."
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

    def rep_compilation_started(rep)
      # Profile compilation
      @rep_times ||= {}
      @rep_times[rep.raw_path] = Time.now
    end

    def rep_compilation_ended(rep)
      # Profile compilation
      @rep_times ||= {}
      @rep_times[rep.raw_path] = Time.now - @rep_times[rep.raw_path]

      # Skip if not outputted
      return unless rep.written?

      # Get action and level
      action = if rep.created?
        :create
      elsif rep.modified?
        :update
      elsif !rep.compiled?
        nil
      else
        :identical
      end

      # Log
      unless action.nil?
        duration = @rep_times[rep.raw_path]
        Nanoc3::CLI::Logger.instance.file(:high, action, rep.raw_path, duration)
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
