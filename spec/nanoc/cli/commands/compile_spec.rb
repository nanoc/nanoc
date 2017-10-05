# frozen_string_literal: true

describe Nanoc::CLI::Commands::Compile, site: true, stdio: true do
  describe '#run' do
    example do
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
  end
end
