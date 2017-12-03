# frozen_string_literal: true

describe Nanoc::RuleDSL::RecordingExecutor do
  let(:executor) { described_class.new(rep) }

  let(:action_sequence) { executor.action_sequence }
  let(:item) { Nanoc::Int::Item.new('stuff', {}, '/foo.md') }
  let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }

  describe '#filter' do
    it 'records filter call without arguments' do
      executor.filter(:erb)

      expect(action_sequence.size).to eql(1)
      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Filter)
      expect(action_sequence[0].filter_name).to eql(:erb)
      expect(action_sequence[0].params).to eql({})
    end

    it 'records filter call with arguments' do
      executor.filter(:erb, x: 123)

      expect(action_sequence.size).to eql(1)
      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Filter)
      expect(action_sequence[0].filter_name).to eql(:erb)
      expect(action_sequence[0].params).to eql(x: 123)
    end
  end

  describe '#layout' do
    it 'records layout call without arguments' do
      executor.layout('/default.*')

      expect(action_sequence.size).to eql(2)

      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(action_sequence[0].snapshot_names).to eql([:pre])
      expect(action_sequence[0].paths).to be_empty

      expect(action_sequence[1]).to be_a(Nanoc::Int::ProcessingActions::Layout)
      expect(action_sequence[1].layout_identifier).to eql('/default.*')
      expect(action_sequence[1].params).to eql({})
    end

    it 'records layout call with arguments' do
      executor.layout('/default.*', donkey: 123)

      expect(action_sequence.size).to eql(2)

      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(action_sequence[0].snapshot_names).to eql([:pre])
      expect(action_sequence[0].paths).to be_empty

      expect(action_sequence[1]).to be_a(Nanoc::Int::ProcessingActions::Layout)
      expect(action_sequence[1].layout_identifier).to eql('/default.*')
      expect(action_sequence[1].params).to eql(donkey: 123)
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
        expect(action_sequence.size).to eql(1)
        expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
        expect(action_sequence[0].snapshot_names).to eql([:foo])
        expect(action_sequence[0].paths).to be_empty
      end
    end

    context 'final argument' do
      subject { executor.snapshot(:foo, path: path) }
      let(:path) { nil }

      context 'routing rule does not exist' do
        context 'no explicit path given' do
          it 'records' do
            subject
            expect(action_sequence.size).to eql(1)
            expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(action_sequence[0].snapshot_names).to eql([:foo])
            expect(action_sequence[0].paths).to be_empty
          end
        end

        context 'explicit path given as string' do
          let(:path) { '/routed-foo.html' }

          it 'records' do
            subject
            expect(action_sequence.size).to eql(1)
            expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(action_sequence[0].snapshot_names).to eql([:foo])
            expect(action_sequence[0].paths).to eql(['/routed-foo.html'])
          end
        end

        context 'explicit path given as identifier' do
          let(:path) { Nanoc::Identifier.from('/routed-foo.html') }

          it 'records' do
            subject
            expect(action_sequence.size).to eql(1)
            expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(action_sequence[0].snapshot_names).to eql([:foo])
            expect(action_sequence[0].paths).to eql(['/routed-foo.html'])
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

      expect(action_sequence.size).to eql(2)
      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(action_sequence[0].snapshot_names).to eql([:foo])
      expect(action_sequence[1]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(action_sequence[1].snapshot_names).to eql([:bar])
    end
  end
end
