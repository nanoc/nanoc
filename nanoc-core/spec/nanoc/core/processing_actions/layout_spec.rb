# frozen_string_literal: true

describe Nanoc::Core::ProcessingActions::Layout do
  let(:action) { described_class.new('/foo.erb', awesome: true) }

  describe '#serialize' do
    subject { action.serialize }

    it { is_expected.to eql([:layout, '/foo.erb', 'v+eiDx9FKFH7+UBdX93/FK7/pRM=']) }
  end

  describe '#to_s' do
    subject { action.to_s }

    it { is_expected.to match(%r{\Alayout "/foo.erb", \{(:awesome=>true|awesome: true)\}\z}) }
  end

  describe '#inspect' do
    subject { action.inspect }

    it { is_expected.to eql('<Nanoc::Core::ProcessingActions::Layout "/foo.erb", "v+eiDx9FKFH7+UBdX93/FK7/pRM=">') }
  end

  describe '#== and #eql?' do
    context 'other action is equal' do
      let(:action_a) { described_class.new('/foo.erb', foo: :bar) }
      let(:action_b) { described_class.new('/foo.erb', foo: :bar) }

      it 'is ==' do
        expect(action_a).to eq(action_b)
      end

      it 'is eql?' do
        expect(action_a).to eql(action_b)
      end
    end

    context 'other action has different identifier' do
      let(:action_a) { described_class.new('/foo.erb', foo: :bar) }
      let(:action_b) { described_class.new('/bar.erb', foo: :bar) }

      it 'is not ==' do
        expect(action_a).not_to eq(action_b)
      end

      it 'is not eql?' do
        expect(action_a).not_to eql(action_b)
      end
    end

    context 'other action has different params' do
      let(:action_a) { described_class.new('/foo.erb', foo: :bar) }
      let(:action_b) { described_class.new('/foo.erb', foo: :oink) }

      it 'is not ==' do
        expect(action_a).not_to eq(action_b)
      end

      it 'is not eql?' do
        expect(action_a).not_to eql(action_b)
      end
    end

    context 'other action is not a layout action' do
      let(:action_a) { described_class.new('/foo.erb', foo: :bar) }
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
      let(:action_a) { described_class.new('/foo.erb', foo: :bar) }
      let(:action_b) { described_class.new('/foo.erb', foo: :bar) }

      it 'is the same' do
        expect(action_a.hash == action_b.hash).to be(true)
      end
    end

    context 'other action has different identifier' do
      let(:action_a) { described_class.new('/foo.erb', foo: :bar) }
      let(:action_b) { described_class.new('/bar.erb', foo: :bar) }

      it 'is the same' do
        expect(action_a.hash == action_b.hash).to be(false)
      end
    end

    context 'other action has different params' do
      let(:action_a) { described_class.new('/foo.erb', foo: :bar) }
      let(:action_b) { described_class.new('/foo.erb', foo: :oink) }

      it 'is the same' do
        expect(action_a.hash == action_b.hash).to be(false)
      end
    end

    context 'other action is not a layout action' do
      let(:action_a) { described_class.new('/foo.erb', foo: :bar) }
      let(:action_b) { :woof }

      it 'is the same' do
        expect(action_a.hash == action_b.hash).to be(false)
      end
    end
  end
end
