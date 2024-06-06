# frozen_string_literal: true

describe Nanoc::Core::ActionSequence do
  let(:action_sequence) { raise 'override me' }

  let(:item) { Nanoc::Core::Item.new('foo', {}, '/foo.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }

  describe '#initialize' do
    context 'with actions' do
      subject { described_class.new(actions:) }

      let(:actions) do
        [
          Nanoc::Core::ProcessingActions::Filter.new(:erb, {}),
        ]
      end

      its(:actions) { is_expected.to be(actions) }
    end

    context 'without actions' do
      subject { described_class.new }

      its(:actions) { is_expected.to be_empty }
    end
  end

  describe '#size' do
    subject { action_sequence.size }

    context 'no actions' do
      let(:action_sequence) do
        Nanoc::Core::ActionSequenceBuilder.build do |b|
        end
      end

      it { is_expected.to be(0) }
    end

    context 'some actions' do
      let(:action_sequence) do
        Nanoc::Core::ActionSequenceBuilder.build do |b|
          b.add_filter(:foo, {})
        end
      end

      it { is_expected.to be(1) }
    end
  end

  describe '#[]' do
    subject { action_sequence[index] }

    let(:index) { 0 }

    context 'no actions' do
      let(:action_sequence) do
        Nanoc::Core::ActionSequenceBuilder.build do |b|
        end
      end

      it { is_expected.to be_nil }
    end

    context 'some actions' do
      let(:action_sequence) do
        Nanoc::Core::ActionSequenceBuilder.build do |b|
          b.add_filter(:foo, {})
        end
      end

      it { is_expected.to be_a(Nanoc::Core::ProcessingActions::Filter) }
    end
  end

  describe '#snapshot_actions' do
    subject { action_sequence.snapshot_actions }

    let(:action_sequence) do
      Nanoc::Core::ActionSequenceBuilder.build do |b|
        b.add_filter(:foo, {})
        b.add_snapshot(:pre, '/page-pre.html', rep)
        b.add_layout('/default.erb', {})
      end
    end

    it { is_expected.to contain_exactly(Nanoc::Core::ProcessingActions::Snapshot.new([:pre], ['/page-pre.html'])) }
  end

  describe '#paths' do
    subject { action_sequence.paths }

    let(:action_sequence) do
      Nanoc::Core::ActionSequenceBuilder.build do |b|
        b.add_snapshot(:pre, '/pre.html', rep)
        b.add_snapshot(:post, '/post.html', rep)
      end
    end

    it { is_expected.to contain_exactly([[:pre], ['/pre.html']], [[:post], ['/post.html']]) }
  end

  describe '#each' do
    let(:action_sequence) do
      Nanoc::Core::ActionSequenceBuilder.build do |b|
        b.add_filter(:erb, awesomeness: 'high')
        b.add_snapshot(:bar, '/foo.md', rep)
        b.add_layout('/default.erb', somelayoutparam: 'yes')
      end
    end

    example do
      actions = action_sequence.map { _1 }
      expect(actions.size).to eq(3)
    end
  end

  describe '#map' do
    let(:action_sequence) do
      Nanoc::Core::ActionSequenceBuilder.build do |b|
        b.add_filter(:erb, awesomeness: 'high')
        b.add_snapshot(:bar, '/foo.md', rep)
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
      Nanoc::Core::ActionSequenceBuilder.build do |b|
        b.add_filter(:erb, awesomeness: 'high')
        b.add_snapshot(:bar, '/foo.md', rep)
        b.add_layout('/default.erb', somelayoutparam: 'yes')
      end
    end

    example do
      expect(subject).to eql(
        [
          [:filter, :erb, 'B1gmzMdP+iEDgTz7SylLoB6yLNw='],
          [:snapshot, [:bar], true, ['/foo.md']],
          [:layout, '/default.erb', 'QQW0vu/3fP4Ihc5xhQKuPer3xUc='],
        ],
      )
    end
  end
end
