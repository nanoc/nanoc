# frozen_string_literal: true

describe Nanoc::CLI::Commands::Compile, site: true, stdio: true do
  describe '#run' do
    it 'starts and stops listeners as needed' do
      test_listener_class = Class.new(::Nanoc::CLI::Commands::CompileListeners::Abstract) do
        def start
          @started = true
        end

        def stop
          @stopped = true
        end

        def started?
          @started
        end

        def stopped?
          @stopped
        end
      end

      expect(Nanoc::CLI::Commands::CompileListeners::Aggregate)
        .to receive(:default_listener_classes)
        .and_return([test_listener_class])

      listener = test_listener_class.new

      expect(test_listener_class)
        .to receive(:new)
        .and_return(listener)

      options = {}
      arguments = []
      cmd = nil
      cmd_runner = Nanoc::CLI::Commands::Compile.new(options, arguments, cmd)

      cmd_runner.run

      expect(listener).to be_started
      expect(listener).to be_stopped
    end

    it 'watches with --watch' do
      pid = fork do
        trap(:INT) { exit(0) }

        # TODO: Use Nanoc::CLI.run instead (when --watch is no longer experimental)
        options = { watch: true }
        arguments = []
        cmd = nil
        cmd_runner = Nanoc::CLI::Commands::Compile.new(options, arguments, cmd)
        cmd_runner.run
      end

      # FIXME: wait is ugly
      sleep 0.5

      File.write('content/lol.html', 'hej')
      sleep_until { File.file?('output/lol.html') }
      expect(File.read('output/lol.html')).to eq('hej')

      sleep 1.0 # HFS+ mtime resolution is 1s
      File.write('content/lol.html', 'bye')
      sleep_until { File.read('output/lol.html') == 'bye' }

      # Stop
      Process.kill('INT', pid)
      Process.waitpid(pid)
    end
  end
end
