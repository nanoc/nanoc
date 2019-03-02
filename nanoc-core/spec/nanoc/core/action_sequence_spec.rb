# frozen_string_literal: true

describe Nanoc::Core::ActionSequence do
  let(:action_sequence) { raise 'override me' }

  let(:item) { Nanoc::Core::Item.new('foo', {}, '/foo.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }

  describe '#size' do
    subject { action_sequence.size }

    context 'no actions' do
      let(:action_sequence) do
        Nanoc::Core::ActionSequenceBuilder.build(rep) do |b|
        end
      end

      it { is_expected.to eql(0) }
    end

    context 'some actions' do
      let(:action_sequence) do
        Nanoc::Core::ActionSequenceBuilder.build(rep) do |b|
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
        Nanoc::Core::ActionSequenceBuilder.build(rep) do |b|
        end
      end

      it { is_expected.to be_nil }
    end

    context 'some actions' do
      let(:action_sequence) do
        Nanoc::Core::ActionSequenceBuilder.build(rep) do |b|
          b.add_filter(:foo, {})
        end
      end

      it { is_expected.to be_a(Nanoc::Core::ProcessingActions::Filter) }
    end
  end

  describe '#snapshot_actions' do
    subject { action_sequence.snapshot_actions }

    let(:action_sequence) do
      Nanoc::Core::ActionSequenceBuilder.build(rep) do |b|
        b.add_filter(:foo, {})
        b.add_snapshot(:pre, '/page-pre.html')
        b.add_layout('/default.erb', {})
      end
    end

    it { is_expected.to contain_exactly(Nanoc::Core::ProcessingActions::Snapshot.new([:pre], ['/page-pre.html'])) }
  end

  describe '#paths' do
    subject { action_sequence.paths }

    let(:action_sequence) do
      Nanoc::Core::ActionSequenceBuilder.build(rep) do |b|
        b.add_snapshot(:pre, '/pre.html')
        b.add_snapshot(:post, '/post.html')
      end
    end

    it { is_expected.to contain_exactly([[:pre], ['/pre.html']], [[:post], ['/post.html']]) }
  end

  describe '#each' do
    let(:action_sequence) do
      Nanoc::Core::ActionSequenceBuilder.build(rep) do |b|
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
      Nanoc::Core::ActionSequenceBuilder.build(rep) do |b|
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
      Nanoc::Core::ActionSequenceBuilder.build(rep) do |b|
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
