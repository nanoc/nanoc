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
end
