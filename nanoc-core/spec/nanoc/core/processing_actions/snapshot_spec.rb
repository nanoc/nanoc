# frozen_string_literal: true

describe Nanoc::Core::ProcessingActions::Snapshot do
  let(:action) { described_class.new([:before_layout], ['/foo.md']) }

  describe '#serialize' do
    subject { action.serialize }
    it { is_expected.to eql([:snapshot, [:before_layout], true, ['/foo.md']]) }
  end

  describe '#to_s' do
    subject { action.to_s }
    it { is_expected.to eql('snapshot [:before_layout], paths: ["/foo.md"]') }
  end

  describe '#inspect' do
    subject { action.inspect }
    it { is_expected.to eql('<Nanoc::Core::ProcessingActions::Snapshot [:before_layout], true, ["/foo.md"]>') }
  end

  describe '#update' do
    context 'with nothing' do
      subject { action.update }
      its(:snapshot_names) { is_expected.to eql([:before_layout]) }
      its(:paths) { is_expected.to eql(['/foo.md']) }
    end

    context 'with snapshot name' do
      subject { action.update(snapshot_names: [:zebra]) }
      its(:snapshot_names) { is_expected.to eql(%i[before_layout zebra]) }
      its(:paths) { is_expected.to eql(['/foo.md']) }
    end

    context 'with paths' do
      subject { action.update(paths: ['/donkey.md', '/giraffe.md']) }
      its(:snapshot_names) { is_expected.to eql([:before_layout]) }
      its(:paths) { is_expected.to eql(['/foo.md', '/donkey.md', '/giraffe.md']) }
    end
  end

  describe '#== and #eql?' do
    context 'other action is equal' do
      let(:action_a) { described_class.new([:erb], ['/foo.html']) }
      let(:action_b) { described_class.new([:erb], ['/foo.html']) }

      it 'is ==' do
        expect(action_a).to eq(action_b)
      end

      it 'is eql?' do
        expect(action_a).to eql(action_b)
      end
    end

    context 'other action has different name' do
      let(:action_a) { described_class.new([:erb], ['/foo.html']) }
      let(:action_b) { described_class.new([:haml], ['/foo.html']) }

      it 'is not ==' do
        expect(action_a).not_to eq(action_b)
      end

      it 'is not eql?' do
        expect(action_a).not_to eql(action_b)
      end
    end

    context 'other action has different paths' do
      let(:action_a) { described_class.new([:erb], ['/foo.html']) }
      let(:action_b) { described_class.new([:erb], ['/foo.htm']) }

      it 'is not ==' do
        expect(action_a).not_to eq(action_b)
      end

      it 'is not eql?' do
        expect(action_a).not_to eql(action_b)
      end
    end

    context 'other action is not a layout action' do
      let(:action_a) { described_class.new([:erb], ['/foo.html']) }
      let(:action_b) { :donkey }

      it 'is not ==' do
        expect(action_a).not_to eq(action_b)
      end

      it 'is not eql?' do
        expect(action_a).not_to eql(action_b)
      end
    end
  end

  describe '#hash' do
    context 'other action is equal' do
      let(:action_a) { described_class.new([:erb], ['/foo.html']) }
      let(:action_b) { described_class.new([:erb], ['/foo.html']) }

      it 'is the same' do
        expect(action_a.hash == action_b.hash).to be(true)
      end
    end

    context 'other action has different name' do
      let(:action_a) { described_class.new([:erb], ['/foo.html']) }
      let(:action_b) { described_class.new([:haml], ['/foo.html']) }

      it 'is the same' do
        expect(action_a.hash == action_b.hash).to be(false)
      end
    end

    context 'other action has different paths' do
      let(:action_a) { described_class.new([:erb], ['/foo.html']) }
      let(:action_b) { described_class.new([:erb], ['/foo.htm']) }

      it 'is the same' do
        expect(action_a.hash == action_b.hash).to be(false)
      end
    end

    context 'other action is not a layout action' do
      let(:action_a) { described_class.new([:erb], ['/foo.html']) }
      let(:action_b) { :woof }

      it 'is the same' do
        expect(action_a.hash == action_b.hash).to be(false)
      end
    end
  end
end
