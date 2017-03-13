describe Nanoc::Int::Compiler::Phases::Abstract do
  subject(:phase) do
    described_class.new(wrapped: wrapped, name: 'my_phase')
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

    let(:phase) do
      Class.new(described_class) do
        def run(_rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
          yield
        end
      end.new(wrapped: wrapped, name: 'my_phase')
    end

    let(:wrapped) do
      Class.new(described_class) do
        def run(_rep, is_outdated:); end
      end.new(wrapped: nil, name: 'wrapped_phase')
    end

    it 'sends the proper notifications' do
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_started, 'my_phase', rep).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_yielded, 'my_phase', rep).ordered

      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_started, 'wrapped_phase', rep).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_ended, 'wrapped_phase', rep).ordered

      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_resumed, 'my_phase', rep).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_ended, 'my_phase', rep).ordered

      subject
    end
  end
end
