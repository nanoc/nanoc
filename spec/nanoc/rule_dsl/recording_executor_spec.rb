describe Nanoc::RuleDSL::RecordingExecutor do
  let(:executor) { described_class.new(rule_memory) }

  let(:rule_memory) { Nanoc::Int::RuleMemory.new(rep) }
  let(:rep) { double(:rep) }

  describe '#filter' do
    it 'records filter call without arguments' do
      executor.filter(:erb)

      expect(rule_memory.size).to eql(1)
      expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Filter)
      expect(rule_memory[0].filter_name).to eql(:erb)
      expect(rule_memory[0].params).to eql({})
    end

    it 'records filter call with arguments' do
      executor.filter(:erb, x: 123)

      expect(rule_memory.size).to eql(1)
      expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Filter)
      expect(rule_memory[0].filter_name).to eql(:erb)
      expect(rule_memory[0].params).to eql({ x: 123 })
    end
  end

  describe '#layout' do
    it 'records layout call without arguments' do
      executor.layout('/default.*')

      expect(rule_memory.size).to eql(2)

      expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(rule_memory[0].snapshot_name).to eql(:pre)
      expect(rule_memory[0]).to be_final
      expect(rule_memory[0].path).to be_nil

      expect(rule_memory[1]).to be_a(Nanoc::Int::ProcessingActions::Layout)
      expect(rule_memory[1].layout_identifier).to eql('/default.*')
      expect(rule_memory[1].params).to eql({})
    end

    it 'records layout call with arguments' do
      executor.layout('/default.*', donkey: 123)

      expect(rule_memory.size).to eql(2)

      expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(rule_memory[0].snapshot_name).to eql(:pre)
      expect(rule_memory[0]).to be_final
      expect(rule_memory[0].path).to be_nil

      expect(rule_memory[1]).to be_a(Nanoc::Int::ProcessingActions::Layout)
      expect(rule_memory[1].layout_identifier).to eql('/default.*')
      expect(rule_memory[1].params).to eql({ donkey: 123 })
    end

    it 'fails when passed a symbol' do
      expect { executor.layout(:default, donkey: 123) }.to raise_error(ArgumentError)
    end
  end

  describe '#snapshot' do
    context 'snapshot already exists' do
      before do
        executor.snapshot(:foo)
      end

      it 'raises when creating same snapshot' do
        expect { executor.snapshot(:foo) }
          .to raise_error(Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName)
      end
    end

    context 'no arguments' do
      subject { executor.snapshot(:foo) }

      it 'records' do
        subject
        expect(rule_memory.size).to eql(1)
        expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
        expect(rule_memory[0].snapshot_name).to eql(:foo)
        expect(rule_memory[0].path).to be_nil
        expect(rule_memory[0]).to be_final
      end
    end

    context 'final argument' do
      subject { executor.snapshot(:foo, path: path) }
      let(:path) { nil }

      context 'routing rule does not exist' do
        context 'no explicit path given' do
          it 'records' do
            subject
            expect(rule_memory.size).to eql(1)
            expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(rule_memory[0].snapshot_name).to eql(:foo)
            expect(rule_memory[0].path).to be_nil
            expect(rule_memory[0]).to be_final
          end
        end

        context 'explicit path given as string' do
          let(:path) { '/routed-foo.html' }

          it 'records' do
            subject
            expect(rule_memory.size).to eql(1)
            expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(rule_memory[0].snapshot_name).to eql(:foo)
            expect(rule_memory[0].path).to eql('/routed-foo.html')
            expect(rule_memory[0]).to be_final
          end
        end

        context 'explicit path given as identifier' do
          let(:path) { Nanoc::Identifier.from('/routed-foo.html') }

          it 'records' do
            subject
            expect(rule_memory.size).to eql(1)
            expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(rule_memory[0].snapshot_name).to eql(:foo)
            expect(rule_memory[0].path).to eql('/routed-foo.html')
            expect(rule_memory[0]).to be_final
          end
        end
      end
    end

    it 'raises when given unknown arguments' do
      expect { executor.snapshot(:foo, animal: 'giraffe') }
        .to raise_error(ArgumentError)
    end

    it 'can create multiple snapshots with different names' do
      executor.snapshot(:foo)
      executor.snapshot(:bar)

      expect(rule_memory.size).to eql(2)
      expect(rule_memory[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(rule_memory[0].snapshot_name).to eql(:foo)
      expect(rule_memory[0]).to be_final
      expect(rule_memory[1]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(rule_memory[1].snapshot_name).to eql(:bar)
      expect(rule_memory[1]).to be_final
    end
  end
end
