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

      it { is_expected.to be_a(Nanoc::Int::RuleMemoryActions::Filter) }
    end
  end

  describe '#add_filter' do
    example do
      rule_memory.add_filter(:foo, donkey: 123)

      expect(rule_memory.size).to eql(1)
      expect(rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Filter)
      expect(rule_memory[0].filter_name).to eql(:foo)
      expect(rule_memory[0].params).to eql(donkey: 123)
    end
  end

  describe '#add_layout' do
    example do
      rule_memory.add_layout('/foo.*', donkey: 123)

      expect(rule_memory.size).to eql(1)
      expect(rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Layout)
      expect(rule_memory[0].layout_identifier).to eql('/foo.*')
      expect(rule_memory[0].params).to eql(donkey: 123)
    end
  end

  describe '#add_snapshot' do
    context 'snapshot does not yet exist' do
      example do
        rule_memory.add_snapshot(:before_layout, false, '/foo.md')

        expect(rule_memory.size).to eql(1)
        expect(rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
        expect(rule_memory[0].snapshot_name).to eql(:before_layout)
        expect(rule_memory[0].path).to eql('/foo.md')
        expect(rule_memory[0]).not_to be_final
      end
    end

    context 'snapshot already exist' do
      before do
        rule_memory.add_snapshot(:before_layout, false, '/bar.md')
      end

      example do
        expect { rule_memory.add_snapshot(:before_layout, false, '/foo.md') }
          .to raise_error(Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName)
      end
    end
  end

  describe '#serialize' do
    subject { rule_memory.serialize }

    before do
      rule_memory.add_filter(:erb, { awesomeness: 123 })
      rule_memory.add_snapshot(:bar, true, '/foo.md')
      rule_memory.add_layout('/default.erb', { somelayoutparam: 444 })
    end

    example do
      expect(subject).to eql(
        [
          [:filter, :erb, 'y9yyZGXu0J04TcDR9oFI3EJM4Vk='],
          [:snapshot, :bar, true, '/foo.md'],
          [:layout, '/default.erb', 'PGQes7wXm3+K06vSBPYUJft57sM='],
        ],
      )
    end
  end
end
