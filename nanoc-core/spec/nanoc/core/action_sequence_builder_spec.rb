# frozen_string_literal: true

describe Nanoc::Core::ActionSequenceBuilder do
  let(:builder) { described_class.new }

  let(:item_rep) { Nanoc::Core::ItemRep.new(item, :default) }
  let(:item) { Nanoc::Core::Item.new('some content', {}, '/foo.md') }

  describe '#add_filter' do
    subject { builder.add_filter(:erb, foo: :bar) }

    it 'adds an action' do
      expect { subject }
        .to change { builder.action_sequence.actions }
        .from([])
        .to([Nanoc::Core::ProcessingActions::Filter.new(:erb, foo: :bar)])
    end
  end

  describe '#add_layout' do
    subject { builder.add_layout('/oink.erb', foo: :bar) }

    it 'adds an action' do
      expect { subject }
        .to change { builder.action_sequence.actions }
        .from([])
        .to([Nanoc::Core::ProcessingActions::Layout.new('/oink.erb', foo: :bar)])
    end
  end

  describe '#add_snapshot' do
    context 'add one snapshot' do
      subject { builder.add_snapshot(:last, '/foo.html', item_rep) }

      it 'adds an action' do
        expect { subject }
          .to change { builder.action_sequence.actions }
          .from([])
          .to([Nanoc::Core::ProcessingActions::Snapshot.new([:last], ['/foo.html'])])
      end
    end

    context 'add two snapshots with same name' do
      subject do
        builder.add_snapshot(:last, '/foo.html', item_rep)
        builder.add_snapshot(:last, '/foo.htm', item_rep)
      end

      it 'raises' do
        expect { subject }
          .to raise_error(Nanoc::Core::ActionSequenceBuilder::CannotCreateMultipleSnapshotsWithSameNameError, 'Attempted to create a snapshot with a duplicate name :last for the item rep /foo.md (rep name :default)')
      end
    end
  end
end
