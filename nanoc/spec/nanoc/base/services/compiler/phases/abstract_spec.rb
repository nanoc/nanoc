# frozen_string_literal: true

describe Nanoc::Int::Compiler::Phases::Abstract do
  subject(:phase) do
    described_class.new(wrapped: wrapped)
  end

  let(:item) { Nanoc::Int::Item.new('foo', {}, '/stuff.md') }
  let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }

  let(:wrapped) { nil }

  describe '#run' do
    subject { phase.run(rep, is_outdated: false) {} }

    it 'raises' do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end

  describe '#call' do
    subject { phase.call(rep, is_outdated: false) }

    let(:phase_class) do
      Class.new(described_class) do
        def self.to_s
          'AbstractSpec::MyTestingPhaseClass'
        end

        def run(_rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
          yield
        end
      end
    end

    let(:phase) { phase_class.new(wrapped: wrapped) }

    let(:wrapped_class) do
      Class.new(described_class) do
        def self.to_s
          'AbstractSpec::MyTestingWrappedPhaseClass'
        end

        def run(_rep, is_outdated:); end
      end
    end

    let(:wrapped) { wrapped_class.new(wrapped: nil) }

    it 'sends the proper notifications' do
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_started, 'MyTestingPhaseClass', rep).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_yielded, 'MyTestingPhaseClass', rep).ordered

      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_started, 'MyTestingWrappedPhaseClass', rep).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_ended, 'MyTestingWrappedPhaseClass', rep).ordered

      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_resumed, 'MyTestingPhaseClass', rep).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_ended, 'MyTestingPhaseClass', rep).ordered

      subject
    end
  end
end
