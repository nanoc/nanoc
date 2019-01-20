# frozen_string_literal: true

describe Nanoc::RuleDSL::ActionRecorder do
  let(:recorder) { described_class.new(rep) }

  let(:action_sequence) { recorder.action_sequence }
  let(:item) { Nanoc::Int::Item.new('stuff', {}, '/foo.md') }
  let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }

  describe '#filter' do
    it 'records filter call without arguments' do
      recorder.filter(:erb)

      expect(action_sequence.size).to eql(1)
      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Filter)
      expect(action_sequence[0].filter_name).to eql(:erb)
      expect(action_sequence[0].params).to eql({})
    end

    it 'records filter call with arguments' do
      recorder.filter(:erb, x: 123)

      expect(action_sequence.size).to eql(1)
      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Filter)
      expect(action_sequence[0].filter_name).to eql(:erb)
      expect(action_sequence[0].params).to eql(x: 123)
    end
  end

  describe '#layout' do
    it 'records layout call without arguments' do
      recorder.layout('/default.*')

      expect(action_sequence.size).to eql(2)

      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(action_sequence[0].snapshot_names).to eql([:pre])
      expect(action_sequence[0].paths).to be_empty

      expect(action_sequence[1]).to be_a(Nanoc::Int::ProcessingActions::Layout)
      expect(action_sequence[1].layout_identifier).to eql('/default.*')
      expect(action_sequence[1].params).to eql({})
    end

    it 'records layout call with arguments' do
      recorder.layout('/default.*', donkey: 123)

      expect(action_sequence.size).to eql(2)

      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(action_sequence[0].snapshot_names).to eql([:pre])
      expect(action_sequence[0].paths).to be_empty

      expect(action_sequence[1]).to be_a(Nanoc::Int::ProcessingActions::Layout)
      expect(action_sequence[1].layout_identifier).to eql('/default.*')
      expect(action_sequence[1].params).to eql(donkey: 123)
    end

    it 'fails when passed a symbol' do
      expect { recorder.layout(:default, donkey: 123) }.to raise_error(ArgumentError)
    end
  end

  describe '#snapshot' do
    context 'snapshot already exists' do
      before do
        recorder.snapshot(:foo)
      end

      it 'raises when creating same snapshot' do
        expect { recorder.snapshot(:foo) }
          .to raise_error(Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName)
      end
    end

    context 'no arguments' do
      subject { recorder.snapshot(:foo) }

      it 'records' do
        subject
        expect(action_sequence.size).to eql(1)
        expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
        expect(action_sequence[0].snapshot_names).to eql([:foo])
        expect(action_sequence[0].paths).to be_empty
      end
    end

    context 'final argument' do
      subject { recorder.snapshot(:foo, subject_params) }
      let(:subject_params) { {} }

      context 'routing rule does not exist' do
        context 'no explicit path given' do
          subject { recorder.snapshot(:foo, subject_params) }

          it 'records' do
            subject
            expect(action_sequence.size).to eql(1)
            expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(action_sequence[0].snapshot_names).to eql([:foo])
            expect(action_sequence[0].paths).to be_empty
          end

          it 'keeps skip_routing_rule' do
            expect { subject }
              .not_to change { recorder.snapshots_for_which_to_skip_routing_rule }
              .from(Set.new)
          end
        end

        context 'explicit path given as string' do
          let(:subject_params) { { path: '/routed-foo.html' } }

          it 'records' do
            subject
            expect(action_sequence.size).to eql(1)
            expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(action_sequence[0].snapshot_names).to eql([:foo])
            expect(action_sequence[0].paths).to eql(['/routed-foo.html'])
          end

          it 'sets skip_routing_rule' do
            expect { subject }
              .to change { recorder.snapshots_for_which_to_skip_routing_rule }
              .from(Set.new)
              .to(Set.new([:foo]))
          end
        end

        context 'explicit path given as identifier' do
          let(:subject_params) { { path: Nanoc::Core::Identifier.from('/routed-foo.html') } }

          it 'records' do
            subject
            expect(action_sequence.size).to eql(1)
            expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(action_sequence[0].snapshot_names).to eql([:foo])
            expect(action_sequence[0].paths).to eql(['/routed-foo.html'])
          end

          it 'sets skip_routing_rule' do
            expect { subject }
              .to change { recorder.snapshots_for_which_to_skip_routing_rule }
              .from(Set.new)
              .to(Set.new([:foo]))
          end
        end

        context 'explicit path given as nil' do
          let(:subject_params) { { path: nil } }

          it 'records' do
            subject
            expect(action_sequence.size).to eql(1)
            expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(action_sequence[0].snapshot_names).to eql([:foo])
            expect(action_sequence[0].paths).to be_empty
          end

          it 'sets skip_routing_rule' do
            expect { subject }
              .to change { recorder.snapshots_for_which_to_skip_routing_rule }
              .from(Set.new)
              .to(Set.new([:foo]))
          end
        end
      end
    end

    it 'raises when given unknown arguments' do
      expect { recorder.snapshot(:foo, animal: 'giraffe') }
        .to raise_error(ArgumentError)
    end

    it 'can create multiple snapshots with different names' do
      recorder.snapshot(:foo)
      recorder.snapshot(:bar)

      expect(action_sequence.size).to eql(2)
      expect(action_sequence[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(action_sequence[0].snapshot_names).to eql([:foo])
      expect(action_sequence[1]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(action_sequence[1].snapshot_names).to eql([:bar])
    end
  end
end
