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
      'Compile all items of the current site.' +
      "\n\n" +
      'By default, only item that are outdated will be compiled. This can ' +
      'speed up the compilation process quite a bit, but items that include ' +
      'content from other items may have to be recompiled manually.'
    end

    def usage
      "nanoc3 compile [options]"
    end

    def option_definitions
      [
        # --all
        {
          :long => 'all', :short => 'a', :argument => :forbidden,
          :desc => '(ignored)'
        },
        # --force
        {
          :long => 'force', :short => 'f', :argument => :forbidden,
          :desc => '(ignored)'
        }
      ]
    end

    def run(options, arguments)
      # Make sure we are in a nanoc site directory
      puts "Loading site data..."
      @base.require_site

      # Check presence of --all option
      if options.has_key?(:all) || options.has_key?(:force)
        $stderr.puts "Warning: the --force option (and its deprecated --all alias) are, as of nanoc 3.2, no longer supported and have no effect."
      end

      # Warn if trying to compile a single item
      if arguments.size == 1
        $stderr.puts '-' * 80
        $stderr.puts 'Note: As of nanoc 3.2, it is no longer possible to compile a single item. When invoking the “compile” command, all items in the site will be compiled.'.make_compatible_with_env
        $stderr.puts '-' * 80
      end

      # Give feedback
      puts "Compiling site..."

      # Initialize profiling stuff
      time_before = Time.now
      @rep_times     = {}
      @filter_times  = {}
      setup_notifications

      # Compile
      @base.site.compiler.run

      # Find reps
      reps = @base.site.items.map { |i| i.reps }.flatten

      # Show skipped reps
      reps.select { |r| !r.compiled? }.each do |rep|
        rep.raw_paths.each do |snapshot_name, filename|
          next if filename.nil?
          duration = @rep_times[filename]
          Nanoc3::CLI::Logger.instance.file(:high, :skip, filename, duration)
        end
      end

      # Show diff
      write_diff_for(reps)

      # Give general feedback
      puts
      puts "Site compiled in #{format('%.2f', Time.now - time_before)}s."

      # Give detailed feedback
      if options.has_key?(:verbose)
        print_profiling_feedback(reps)
      end
    end

  private

    def setup_notifications
      # File notifications
      Nanoc3::NotificationCenter.on(:rep_written) do |rep, path, is_created, is_modified|
        action = (is_created ? :create : (is_modified ? :update : :identical))
        duration = Time.now - @rep_times[rep.raw_path] if @rep_times[rep.raw_path]
        Nanoc3::CLI::Logger.instance.file(:high, action, path, duration)
      end

      # Debug notifications
      Nanoc3::NotificationCenter.on(:compilation_started) do |rep|
        puts "*** Started compilation of #{rep.inspect}" if @base.debug?
      end
      Nanoc3::NotificationCenter.on(:compilation_ended) do |rep|
        puts "*** Ended compilation of #{rep.inspect}" if @base.debug?
      end
      Nanoc3::NotificationCenter.on(:compilation_failed) do |rep|
        puts "*** Suspended compilation of #{rep.inspect} due to unmet dependencies" if @base.debug?
      end
      Nanoc3::NotificationCenter.on(:cached_content_used) do |rep|
        puts "*** Used cached compiled content for #{rep.inspect} instead of recompiling" if @base.debug?
      end

      # Timing notifications
      Nanoc3::NotificationCenter.on(:compilation_started) do |rep|
        @rep_times[rep.raw_path] = Time.now
      end
      Nanoc3::NotificationCenter.on(:compilation_ended) do |rep|
        @rep_times[rep.raw_path] = Time.now - @rep_times[rep.raw_path]
      end
      Nanoc3::NotificationCenter.on(:filtering_started) do |rep, filter_name|
        @filter_times[filter_name] = Time.now
        start_filter_progress(rep, filter_name)
      end
      Nanoc3::NotificationCenter.on(:filtering_ended) do |rep, filter_name|
        @filter_times[filter_name] = Time.now - @filter_times[filter_name]
        stop_filter_progress(rep, filter_name)
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
        # FIXME this may break for other lines starting with --- or +++
        diff.sub!(/^--- .*/,    '--- ' + rep.raw_path)
        diff.sub!(/^\+\+\+ .*/, '+++ ' + rep.raw_path)

        # Add
        full_diff << diff
      end

      # Write
      File.open('output.diff', 'w') { |io| io.write(full_diff) }
    end

    def start_filter_progress(rep, filter_name)
      @progress_thread = Thread.new do
        delay = 1.0
        step  = 0

        text = "Running #{filter_name} filter… "

        while !Thread.current[:stopped]
          sleep 0.1

          delay -= 0.1
          next if !$stdout.tty? || delay > 0.05

          $stdout.print text + %w( | / - \\ )[step] + "\r"
          step = (step + 1) % 4
        end

        if $stdout.tty? && delay < 0.05
          $stdout.print ' ' * (text.length + 1 + 1) + "\r"
        end
      end
    end

    def stop_filter_progress(rep, filter_name)
      @progress_thread[:stopped] = true
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

  end

end
