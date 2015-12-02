describe Nanoc::Int::RecordingExecutor do
  let(:executor) { described_class.new(rep) }

  let(:rep) { double(:rep) }

  describe '#filter' do
    it 'records filter call without arguments' do
      executor.filter(rep, :erb)

      expect(executor.rule_memory.size).to eql(1)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Filter)
      expect(executor.rule_memory[0].filter_name).to eql(:erb)
      expect(executor.rule_memory[0].params).to eql({})
    end

    it 'records filter call with arguments' do
      executor.filter(rep, :erb, x: 123)

      expect(executor.rule_memory.size).to eql(1)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Filter)
      expect(executor.rule_memory[0].filter_name).to eql(:erb)
      expect(executor.rule_memory[0].params).to eql({ x: 123 })
    end
  end

  describe '#layout' do
    it 'records layout call without arguments' do
      executor.layout(rep, '/default.*')

      expect(executor.rule_memory.size).to eql(1)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Layout)
      expect(executor.rule_memory[0].layout_identifier).to eql('/default.*')
      expect(executor.rule_memory[0].params).to eql({})
    end

    it 'records layout call with arguments' do
      executor.layout(rep, '/default.*', final: false)

      expect(executor.rule_memory.size).to eql(1)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Layout)
      expect(executor.rule_memory[0].layout_identifier).to eql('/default.*')
      expect(executor.rule_memory[0].params).to eql({ final: false })
    end
  end

  describe '#snapshot' do
    context 'snapshot already exists' do
      before do
        executor.snapshot(rep, :foo)
      end

      it 'raises when creating same snapshot' do
        expect { executor.snapshot(rep, :foo) }
          .to raise_error(Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName)
      end
    end

    it 'records snapshot call without arguments' do
      executor.snapshot(rep, :foo)

      expect(executor.rule_memory.size).to eql(1)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
      expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
      expect(executor.rule_memory[0]).to be_final
    end

    it 'records snapshot call with arguments' do
      executor.snapshot(rep, :foo, final: false)

      expect(executor.rule_memory.size).to eql(1)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
      expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
      expect(executor.rule_memory[0]).not_to be_final
    end

    it 'raises when given unknown arguments' do
      expect { executor.snapshot(rep, :foo, animal: 'giraffe') }
        .to raise_error(ArgumentError)
    end

    it 'can create multiple snapshots with different names' do
      executor.snapshot(rep, :foo)
      executor.snapshot(rep, :bar)

      expect(executor.rule_memory.size).to eql(2)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
      expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
      expect(executor.rule_memory[0]).to be_final
      expect(executor.rule_memory[1]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
      expect(executor.rule_memory[1].snapshot_name).to eql(:bar)
      expect(executor.rule_memory[1]).to be_final
    end
  end

  describe '#record_write' do
    it 'records write call' do
      executor.record_write(rep, '/about.html')

      expect(executor.rule_memory.size).to eql(1)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Write)
      expect(executor.rule_memory[0].path).to eql('/about.html')
    end
  end
end
