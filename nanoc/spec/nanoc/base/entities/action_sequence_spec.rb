# frozen_string_literal: true

describe Nanoc::Int::ActionSequence do
  let(:action_sequence) { raise 'override me' }

  let(:item) { Nanoc::Core::Item.new('foo', {}, '/foo.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }

  describe '#size' do
    subject { action_sequence.size }

    context 'no actions' do
      let(:action_sequence) do
        Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
        end
      end

      it { is_expected.to eql(0) }
    end

    context 'some actions' do
      let(:action_sequence) do
        Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
          b.add_filter(:foo, {})
        end
      end

      it { is_expected.to eql(1) }
    end
  end

  describe '#[]' do
    subject { action_sequence[index] }
    let(:index) { 0 }

    context 'no actions' do
      let(:action_sequence) do
        Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
        end
      end

      it { is_expected.to be_nil }
    end

    context 'some actions' do
      let(:action_sequence) do
        Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
          b.add_filter(:foo, {})
        end
      end

      it { is_expected.to be_a(Nanoc::Core::ProcessingActions::Filter) }
    end
  end

  describe '#add_filter' do
    let(:action_sequence) do
      Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
        b.add_filter(:foo, donkey: 123)
      end
    end

    example do
      expect(action_sequence.size).to eql(1)
      expect(action_sequence[0]).to be_a(Nanoc::Core::ProcessingActions::Filter)
      expect(action_sequence[0].filter_name).to eql(:foo)
      expect(action_sequence[0].params).to eql(donkey: 123)
    end
  end

  describe '#add_layout' do
    let(:action_sequence) do
      Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
        b.add_layout('/foo.*', donkey: 123)
      end
    end

    example do
      expect(action_sequence.size).to eql(1)
      expect(action_sequence[0]).to be_a(Nanoc::Core::ProcessingActions::Layout)
      expect(action_sequence[0].layout_identifier).to eql('/foo.*')
      expect(action_sequence[0].params).to eql(donkey: 123)
    end
  end

  describe '#add_snapshot' do
    context 'snapshot does not yet exist' do
      let(:action_sequence) do
        Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
          b.add_snapshot(:before_layout, '/foo.md')
        end
      end

      example do
        expect(action_sequence.size).to eql(1)
        expect(action_sequence[0]).to be_a(Nanoc::Core::ProcessingActions::Snapshot)
        expect(action_sequence[0].snapshot_names).to eql([:before_layout])
        expect(action_sequence[0].paths).to eql(['/foo.md'])
      end
    end

    context 'snapshot already exist' do
      it 'raises' do
        Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
          b.add_snapshot(:before_layout, '/bar.md')
          expect { b.add_snapshot(:before_layout, '/foo.md') }
            .to raise_error(Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName)
        end
      end
    end
  end

  describe '#each' do
    let(:action_sequence) do
      Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
        b.add_filter(:erb, awesomeness: 'high')
        b.add_snapshot(:bar, '/foo.md')
        b.add_layout('/default.erb', somelayoutparam: 'yes')
      end
    end

    example do
      actions = []
      action_sequence.each { |a| actions << a }
      expect(actions.size).to eq(3)
    end
  end

  describe '#map' do
    let(:action_sequence) do
      Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
        b.add_filter(:erb, awesomeness: 'high')
        b.add_snapshot(:bar, '/foo.md')
        b.add_layout('/default.erb', somelayoutparam: 'yes')
      end
    end

    example do
      res = action_sequence.map { Nanoc::Core::ProcessingActions::Filter.new(:donkey, {}) }
      expect(res.to_a.size).to eq(3)
      expect(res.to_a).to all(be_a(Nanoc::Core::ProcessingActions::Filter))
    end
  end

  describe '#serialize' do
    subject { action_sequence.serialize }

    let(:action_sequence) do
      Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
        b.add_filter(:erb, awesomeness: 'high')
        b.add_snapshot(:bar, '/foo.md')
        b.add_layout('/default.erb', somelayoutparam: 'yes')
      end
    end

    example do
      expect(subject).to eql(
        [
          [:filter, :erb, 'PeWUm2PtXYtqeHJdTqnY7kkwAow='],
          [:snapshot, [:bar], true, ['/foo.md']],
          [:layout, '/default.erb', '97LAe1pYTLKczxBsu+x4MmvqdkU='],
        ],
      )
    end
  end
end
