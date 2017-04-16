describe Nanoc::Int::ActionSequence do
  let(:action_sequence) { raise 'override me' }

  let(:item) { Nanoc::Int::Item.new('foo', {}, '/foo.md') }
  let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }

  describe '#size' do
    subject { action_sequence.size }

    context 'no actions' do
      let(:action_sequence) do
        described_class.build(rep) do |b|
        end
      end

      it { is_expected.to eql(0) }
    end

    context 'some actions' do
      let(:action_sequence) do
        described_class.build(rep) do |b|
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
        described_class.build(rep) do |b|
        end
      end

      it { is_expected.to be_nil }
    end

    context 'some actions' do
      let(:action_sequence) do
        described_class.build(rep) do |b|
          b.add_filter(:foo, {})
        end
      end

      it { is_expected.to be_a(Nanoc::Int::ProcessingActions::Filter) }
    end
  end

  describe '#add_filter' do
    let(:action_sequence) do
      described_class.build(rep) do |b|
        b.add_filter(:foo, donkey: 123)
      end
    end

    example do
      expect(action_sequence.size).to eql(1)
      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Filter)
      expect(action_sequence[0].filter_name).to eql(:foo)
      expect(action_sequence[0].params).to eql(donkey: 123)
    end
  end

  describe '#add_layout' do
    let(:action_sequence) do
      described_class.build(rep) do |b|
        b.add_layout('/foo.*', donkey: 123)
      end
    end

    example do
      expect(action_sequence.size).to eql(1)
      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Layout)
      expect(action_sequence[0].layout_identifier).to eql('/foo.*')
      expect(action_sequence[0].params).to eql(donkey: 123)
    end
  end

  describe '#add_snapshot' do
    context 'snapshot does not yet exist' do
      let(:action_sequence) do
        described_class.build(rep) do |b|
          b.add_snapshot(:before_layout, '/foo.md')
        end
      end

      example do
        expect(action_sequence.size).to eql(1)
        expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
        expect(action_sequence[0].snapshot_names).to eql([:before_layout])
        expect(action_sequence[0].paths).to eql(['/foo.md'])
      end
    end

    context 'snapshot already exist' do
      it 'raises' do
        described_class.build(rep) do |b|
          b.add_snapshot(:before_layout, '/bar.md')
          expect { b.add_snapshot(:before_layout, '/foo.md') }
            .to raise_error(Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName)
        end
      end
    end
  end

  describe '#each' do
    let(:action_sequence) do
      described_class.build(rep) do |b|
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
      described_class.build(rep) do |b|
        b.add_filter(:erb, awesomeness: 'high')
        b.add_snapshot(:bar, '/foo.md')
        b.add_layout('/default.erb', somelayoutparam: 'yes')
      end
    end

    example do
      res = action_sequence.map { Nanoc::Int::ProcessingActions::Filter.new(:donkey, {}) }
      expect(res.to_a.size).to eq(3)
      expect(res.to_a).to all(be_a(Nanoc::Int::ProcessingActions::Filter))
    end
  end

  describe '#serialize' do
    subject { action_sequence.serialize }

    let(:action_sequence) do
      described_class.build(rep) do |b|
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

  describe '#snapshots_defs' do
    let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }
    let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }

    Class.new(Nanoc::Filter) do
      identifier :RuleMemSpec_filter_b2b
      type :binary => :binary # rubocop:disable Style/HashSyntax

      def run(content, params = {}); end
    end

    Class.new(Nanoc::Filter) do
      identifier :RuleMemSpec_filter_b2t
      type :binary => :text # rubocop:disable Style/HashSyntax

      def run(content, params = {}); end
    end

    Class.new(Nanoc::Filter) do
      identifier :RuleMemSpec_filter_t2t
      type :text => :text # rubocop:disable Style/HashSyntax

      def run(content, params = {}); end
    end

    Class.new(Nanoc::Filter) do
      identifier :RuleMemSpec_filter_t2b
      type :text => :binary # rubocop:disable Style/HashSyntax

      def run(content, params = {}); end
    end

    it 'has no snapshot defs by default' do
      action_sequence =
        described_class.build(rep) do |b|
        end

      expect(action_sequence.snapshots_defs).to be_empty
    end

    context 'textual item' do
      let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }

      it 'generates initial textual snapshot def' do
        action_sequence =
          described_class.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
          end

        expect(action_sequence.snapshots_defs.size).to eq(1)
        expect(action_sequence.snapshots_defs[0].name).to eq(:giraffe)
        expect(action_sequence.snapshots_defs[0]).not_to be_binary
      end

      it 'generated follow-up textual snapshot def if previous filter is textual' do
        action_sequence =
          described_class.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
            b.add_filter(:RuleMemSpec_filter_t2t, arguments: 'irrelevant')
            b.add_snapshot(:zebra, nil)
          end

        expect(action_sequence.snapshots_defs.size).to eq(2)
        expect(action_sequence.snapshots_defs[0].name).to eq(:giraffe)
        expect(action_sequence.snapshots_defs[0]).not_to be_binary
        expect(action_sequence.snapshots_defs[1].name).to eq(:zebra)
        expect(action_sequence.snapshots_defs[1]).not_to be_binary
      end

      it 'generated follow-up binary snapshot def if previous filter is text-to-bianry' do
        action_sequence =
          described_class.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
            b.add_filter(:RuleMemSpec_filter_t2b, arguments: 'irrelevant')
            b.add_snapshot(:zebra, nil)
          end

        expect(action_sequence.snapshots_defs.size).to eq(2)
        expect(action_sequence.snapshots_defs[0].name).to eq(:giraffe)
        expect(action_sequence.snapshots_defs[0]).not_to be_binary
        expect(action_sequence.snapshots_defs[1].name).to eq(:zebra)
        expect(action_sequence.snapshots_defs[1]).to be_binary
      end
    end

    context 'binary item' do
      let(:item) { Nanoc::Int::Item.new(Nanoc::Int::BinaryContent.new('/asdf.dat'), {}, '/foo.md') }

      it 'generates initial binary snapshot def' do
        action_sequence =
          described_class.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
          end

        expect(action_sequence.snapshots_defs.size).to eq(1)
        expect(action_sequence.snapshots_defs[0].name).to eq(:giraffe)
        expect(action_sequence.snapshots_defs[0]).to be_binary
      end

      it 'generated follow-up binary snapshot def if previous filter is binary' do
        action_sequence =
          described_class.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
            b.add_filter(:RuleMemSpec_filter_b2b, arguments: 'irrelevant')
            b.add_snapshot(:zebra, nil)
          end

        expect(action_sequence.snapshots_defs.size).to eq(2)
        expect(action_sequence.snapshots_defs[0].name).to eq(:giraffe)
        expect(action_sequence.snapshots_defs[0]).to be_binary
        expect(action_sequence.snapshots_defs[1].name).to eq(:zebra)
        expect(action_sequence.snapshots_defs[1]).to be_binary
      end

      it 'generated follow-up textual snapshot def if previous filter is binary-to-text' do
        action_sequence =
          described_class.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
            b.add_filter(:RuleMemSpec_filter_b2t, arguments: 'irrelevant')
            b.add_snapshot(:zebra, nil)
          end

        expect(action_sequence.snapshots_defs.size).to eq(2)
        expect(action_sequence.snapshots_defs[0].name).to eq(:giraffe)
        expect(action_sequence.snapshots_defs[0]).to be_binary
        expect(action_sequence.snapshots_defs[1].name).to eq(:zebra)
        expect(action_sequence.snapshots_defs[1]).not_to be_binary
      end
    end
  end
end
