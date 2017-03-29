describe Nanoc::Int::RuleMemory do
  let(:rule_memory) { described_class.new(rep) }
  let(:rep) { double(:rep) }

  describe '#size' do
    subject { rule_memory.size }

    context 'no actions' do
      it { is_expected.to eql(0) }
    end

    context 'some actions' do
      before do
        rule_memory.add_filter(:foo, {})
      end

      it { is_expected.to eql(1) }
    end
  end

  describe '#[]' do
    subject { rule_memory[index] }
    let(:index) { 0 }

    context 'no actions' do
      it { is_expected.to be_nil }
    end

    context 'some actions' do
      before do
        rule_memory.add_filter(:foo, {})
      end

      it { is_expected.to be_a(Nanoc::Int::ProcessingActions::Filter) }
    end
  end

  describe '#add_filter' do
    example do
      rule_memory.add_filter(:foo, donkey: 123)

      expect(rule_memory.size).to eql(1)
      expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Filter)
      expect(rule_memory[0].filter_name).to eql(:foo)
      expect(rule_memory[0].params).to eql(donkey: 123)
    end
  end

  describe '#add_layout' do
    example do
      rule_memory.add_layout('/foo.*', donkey: 123)

      expect(rule_memory.size).to eql(1)
      expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Layout)
      expect(rule_memory[0].layout_identifier).to eql('/foo.*')
      expect(rule_memory[0].params).to eql(donkey: 123)
    end
  end

  describe '#add_snapshot' do
    context 'snapshot does not yet exist' do
      example do
        rule_memory.add_snapshot(:before_layout, '/foo.md')

        expect(rule_memory.size).to eql(1)
        expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
        expect(rule_memory[0].snapshot_names).to eql([:before_layout])
        expect(rule_memory[0].paths).to eql(['/foo.md'])
      end
    end

    context 'snapshot already exist' do
      before do
        rule_memory.add_snapshot(:before_layout, '/bar.md')
      end

      it 'raises' do
        expect { rule_memory.add_snapshot(:before_layout, '/foo.md') }
          .to raise_error(Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName)
      end
    end
  end

  describe '#each' do
    before do
      rule_memory.add_filter(:erb, awesomeness: 'high')
      rule_memory.add_snapshot(:bar, '/foo.md')
      rule_memory.add_layout('/default.erb', somelayoutparam: 'yes')
    end

    example do
      actions = []
      rule_memory.each { |a| actions << a }
      expect(actions.size).to eq(3)
    end
  end

  describe '#map' do
    before do
      rule_memory.add_filter(:erb, awesomeness: 'high')
      rule_memory.add_snapshot(:bar, '/foo.md')
      rule_memory.add_layout('/default.erb', somelayoutparam: 'yes')
    end

    example do
      res = rule_memory.map { Nanoc::Int::ProcessingActions::Filter.new(:donkey, {}) }
      expect(res.to_a.size).to eq(3)
      expect(res.to_a).to all(be_a(Nanoc::Int::ProcessingActions::Filter))
    end
  end

  describe '#serialize' do
    subject { rule_memory.serialize }

    before do
      rule_memory.add_filter(:erb, awesomeness: 'high')
      rule_memory.add_snapshot(:bar, '/foo.md')
      rule_memory.add_layout('/default.erb', somelayoutparam: 'yes')
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

  describe '#compact_snapshots' do
    subject { rule_memory.compact_snapshots }

    before do
      rule_memory.add_snapshot(:a1, nil)
      rule_memory.add_snapshot(:a2, '/a2.md')
      rule_memory.add_snapshot(:a3, nil)
      rule_memory.add_filter(:erb, awesomeness: 'high')
      rule_memory.add_snapshot(:b1, '/b1.md')
      rule_memory.add_snapshot(:b2, nil)
      rule_memory.add_snapshot(:b3, '/b3.md')
      rule_memory.add_filter(:erb, awesomeness: 'high')
      rule_memory.add_snapshot(:c, nil)
    end

    example do
      expect(subject[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(subject[0].snapshot_names).to eql(%i(a1 a2 a3))
      expect(subject[0].paths).to eql(['/a2.md'])

      expect(subject[1]).to be_a(Nanoc::Int::ProcessingActions::Filter)

      expect(subject[2]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(subject[2].snapshot_names).to eql(%i(b1 b2 b3))
      expect(subject[2].paths).to eql(['/b1.md', '/b3.md'])

      expect(subject[3]).to be_a(Nanoc::Int::ProcessingActions::Filter)

      expect(subject[4]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(subject[4].snapshot_names).to eql([:c])
      expect(subject[4].paths).to be_empty

      expect(subject.size).to eql(5)
    end
  end

  describe '#snapshots_defs' do
    subject { rule_memory.snapshots_defs }

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
      expect(subject).to be_empty
    end

    context 'textual item' do
      let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }

      it 'generates initial textual snapshot def' do
        rule_memory.add_snapshot(:giraffe, nil)

        expect(subject.size).to eq(1)
        expect(subject[0].name).to eq(:giraffe)
        expect(subject[0]).not_to be_binary
      end

      it 'generated follow-up textual snapshot def if previous filter is textual' do
        rule_memory.add_snapshot(:giraffe, nil)
        rule_memory.add_filter(:RuleMemSpec_filter_t2t, arguments: 'irrelevant')
        rule_memory.add_snapshot(:zebra, nil)

        expect(subject.size).to eq(2)
        expect(subject[0].name).to eq(:giraffe)
        expect(subject[0]).not_to be_binary
        expect(subject[1].name).to eq(:zebra)
        expect(subject[1]).not_to be_binary
      end

      it 'generated follow-up binary snapshot def if previous filter is text-to-bianry' do
        rule_memory.add_snapshot(:giraffe, nil)
        rule_memory.add_filter(:RuleMemSpec_filter_t2b, arguments: 'irrelevant')
        rule_memory.add_snapshot(:zebra, nil)

        expect(subject.size).to eq(2)
        expect(subject[0].name).to eq(:giraffe)
        expect(subject[0]).not_to be_binary
        expect(subject[1].name).to eq(:zebra)
        expect(subject[1]).to be_binary
      end
    end

    context 'binary item' do
      let(:item) { Nanoc::Int::Item.new(Nanoc::Int::BinaryContent.new('/asdf.dat'), {}, '/foo.md') }

      it 'generates initial binary snapshot def' do
        rule_memory.add_snapshot(:giraffe, nil)

        expect(subject.size).to eq(1)
        expect(subject[0].name).to eq(:giraffe)
        expect(subject[0]).to be_binary
      end

      it 'generated follow-up binary snapshot def if previous filter is binary' do
        rule_memory.add_snapshot(:giraffe, nil)
        rule_memory.add_filter(:RuleMemSpec_filter_b2b, arguments: 'irrelevant')
        rule_memory.add_snapshot(:zebra, nil)

        expect(subject.size).to eq(2)
        expect(subject[0].name).to eq(:giraffe)
        expect(subject[0]).to be_binary
        expect(subject[1].name).to eq(:zebra)
        expect(subject[1]).to be_binary
      end

      it 'generated follow-up textual snapshot def if previous filter is binary-to-text' do
        rule_memory.add_snapshot(:giraffe, nil)
        rule_memory.add_filter(:RuleMemSpec_filter_b2t, arguments: 'irrelevant')
        rule_memory.add_snapshot(:zebra, nil)

        expect(subject.size).to eq(2)
        expect(subject[0].name).to eq(:giraffe)
        expect(subject[0]).to be_binary
        expect(subject[1].name).to eq(:zebra)
        expect(subject[1]).not_to be_binary
      end
    end
  end
end
