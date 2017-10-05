# frozen_string_literal: true

describe Nanoc::CLI::Commands::CompileListeners::Abstract do
  let(:klass) do
    Class.new(described_class) do
      attr_reader :started
      attr_reader :stopped

      def initialize
        @started = false
        @stopped = false
      end

      def start
        @started = true
      end

      def stop
        @stopped = true
      end
    end
  end

  subject { klass.new }

  it 'starts' do
    subject.start
    expect(subject.started).to be
  end

  it 'stops' do
    subject.start
    subject.stop
    expect(subject.stopped).to be
  end

  it 'starts safely' do
    subject.start_safely
    expect(subject.started).to be
  end

  it 'stops safely' do
    subject.start_safely
    subject.stop_safely
    expect(subject.stopped).to be
  end

  context 'listener that does not start or stop properly' do
    let(:klass) do
      Class.new(described_class) do
        def start
          raise 'boom'
        end

        def stop
          raise 'boom'
        end
      end
    end

    it 'raises on start, but not stop' do
      expect { subject.start_safely }.to raise_error(RuntimeError)
      expect { subject.stop_safely }.not_to raise_error
    end
  end
end
