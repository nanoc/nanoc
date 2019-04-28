# frozen_string_literal: true

module Nanoc::Live
  class LiveRecompiler
    def initialize(command_runner:)
      @command_runner = command_runner
    end

    def run
      run_parent do |site|
        handle_changes(site, @command_runner)
      end
    end

    private

    def gen_changes_for_child(site)
      changes = [
        site.data_source.item_changes,
        site.data_source.layout_changes,
        gen_config_and_rules_changes,
      ]

      SlowEnumeratorTools.batch(SlowEnumeratorTools.merge(changes))
    end

    def run_child(pipe_write, pipe_read)
      pipe_write.close

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      changes_enum = gen_changes_for_child(site)
      yield(site)

      quit = Object.new
      parent_enum = Enumerator.new do |y|
        pipe_read.read
        y << quit
      end

      puts 'Listening for site changes…'
      SlowEnumeratorTools.merge([parent_enum, changes_enum]).each do |e|
        break if quit.equal?(e)

        $stderr.print 'Reloading site… '
        $stderr.flush
        site_loader = Nanoc::Int::SiteLoader.new
        site = Nanoc::Core::Site.new(
          config: Nanoc::Int::ConfigLoader.new.new_from_cwd,
          data_source: site_loader.gen_data_source_for_config(site.config),
          code_snippets: site.code_snippets,
        )
        $stderr.puts 'done'

        yield(site)
      end

      exit 0
    rescue Interrupt
      exit 0
    end

    def run_parent
      # create initial child
      pipe_read, pipe_write = IO.pipe
      fork { run_child(pipe_write, pipe_read) { |s| yield(s) } }
      pipe_read.close

      changes = gen_lib_changes
      puts 'Listening for lib/ changes…'
      changes.each do |_e|
        # stop child
        pipe_write.write('q')
        pipe_write.close
        Process.wait

        # create new child
        pipe_read, pipe_write = IO.pipe
        fork { run_child(pipe_write, pipe_read) { |s| yield(s) } }
        pipe_read.close
      end
    rescue Interrupt
    end

    def handle_changes(site, command_runner)
      Nanoc::CLI::ErrorHandler.handle_while(exit_on_error: false) do
        unsafe_handle_changes(site, command_runner)
      end
    end

    def unsafe_handle_changes(site, command_runner)
      time_before = Time.now

      puts 'Compiling site…'
      compiler = Nanoc::Int::Compiler.new_for(site)
      listener = Nanoc::CLI::Commands::CompileListeners::Aggregate.new(
        command_runner: command_runner,
        site: site,
        compiler: compiler,
      )
      listener.run_while do
        compiler.run_until_end
      end

      time_after = Time.now
      puts "Site compiled in #{format('%.2f', time_after - time_before)}s."
      puts
    end

    def gen_lib_changes
      Nanoc::ChangesStream.new do |cl|
        opts = {
          latency: 0.0,
          wait_for_delay: 0.0,
        }

        listener = Listen.to('lib', opts) { |*| cl.lib }
        listener.start
        sleep
      end
    end

    def gen_config_and_rules_changes
      Nanoc::ChangesStream.new do |cl|
        opts = {
          only: /(\/|\A)(nanoc\.yaml|config\.yaml|rules|Rules|rules\.rb|Rules\.rb)\z/,
          latency: 0.0,
          wait_for_delay: 0.0,
        }

        listener = Listen.to('.', opts) { |*| cl.unknown }
        listener.start
        sleep
      end
    end
  end
end
