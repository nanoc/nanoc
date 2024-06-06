# frozen_string_literal: true

describe Nanoc::CLI::Commands::Compile, site: true, stdio: true do
  describe '#run' do
    let(:site) do
      Nanoc::Core::Site.new(
        config:,
        code_snippets:,
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )
    end

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: {}).with_defaults }
    let(:items) { Nanoc::Core::ItemCollection.new(config, []) }
    let(:layouts) { Nanoc::Core::LayoutCollection.new(config, []) }
    let(:code_snippets) { [] }

    it 'starts and stops listeners as needed' do
      test_listener_class = Class.new(Nanoc::CLI::CompileListeners::Abstract) do
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

      expect(Nanoc::CLI::CompileListeners::Aggregate)
        .to receive(:default_listener_classes)
        .and_return([test_listener_class])

      listener = test_listener_class.new

      expect(test_listener_class)
        .to receive(:new)
        .and_return(listener)

      options = {}
      arguments = []
      cmd = nil
      cmd_runner = described_class.new(options, arguments, cmd)

      cmd_runner.run

      expect(listener).to be_started
      expect(listener).to be_stopped
    end

    describe '--watch', fork: true do
      it 'watches with --watch' do
        pipe_stdout_read, pipe_stdout_write = IO.pipe
        pid = fork do
          trap(:INT) { exit(0) }

          pipe_stdout_read.close
          $stdout = pipe_stdout_write

          # TODO: Use Nanoc::CLI.run instead (when --watch is no longer experimental)
          options = { watch: true }
          arguments = []
          cmd = nil
          cmd_runner = described_class.new(options, arguments, cmd)
          cmd_runner.run
        end
        pipe_stdout_write.close

        # Wait until ready
        Timeout.timeout(5) do
          progress = 0
          pipe_stdout_read.each_line do |line|
            progress += 1 if line.start_with?('Listening for lib/ changes')
            progress += 1 if line.start_with?('Listening for site changes')
            break if progress == 2
          end
        end
        sleep 0.5 # Still needs time to warm up…

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
end
