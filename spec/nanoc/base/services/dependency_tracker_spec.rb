describe Nanoc::Int::DependencyTracker do
  let(:tracker) { described_class.new(store) }

  let(:store) { Nanoc::Int::DependencyStore.new([]) }

  let(:item_a) { Nanoc::Int::Item.new('a', {}, '/a.md') }
  let(:item_b) { Nanoc::Int::Item.new('b', {}, '/b.md') }
  let(:item_c) { Nanoc::Int::Item.new('c', {}, '/c.md') }

  shared_examples 'a null dependency tracker' do
    let(:tracker) { Nanoc::Int::DependencyTracker::Null.new }

    example do
      expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_a) }
    end

    example do
      expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_b) }
    end

    example do
      expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_c) }
    end

    example do
      expect { subject }.not_to change { store.objects_outdated_due_to(item_a) }
    end

    example do
      expect { subject }.not_to change { store.objects_outdated_due_to(item_b) }
    end

    example do
      expect { subject }.not_to change { store.objects_outdated_due_to(item_c) }
    end
  end

  describe '#enter and exit' do
    context 'enter' do
      subject do
        tracker.enter(item_a)
      end

      it_behaves_like 'a null dependency tracker'

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_a) }
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_c) }
      end

      example do
        expect { subject }.not_to change { store.objects_outdated_due_to(item_a) }
      end

      example do
        expect { subject }.not_to change { store.objects_outdated_due_to(item_b) }
      end

      example do
        expect { subject }.not_to change { store.objects_outdated_due_to(item_c) }
      end
    end

    context 'enter + enter' do
      subject do
        tracker.enter(item_a)
        tracker.enter(item_b)
      end

      it_behaves_like 'a null dependency tracker'

      it 'changes predecessors of item A' do
        expect { subject }.to change { store.objects_causing_outdatedness_of(item_a) }
          .from([]).to([item_b])
      end

      it 'changes successors of item B' do
        expect { subject }.to change { store.objects_outdated_due_to(item_b) }
          .from([]).to([item_a])
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_c) }
      end

      example do
        expect { subject }.not_to change { store.objects_outdated_due_to(item_a) }
      end

      example do
        expect { subject }.not_to change { store.objects_outdated_due_to(item_c) }
      end
    end

    context 'enter + enter + exit + enter' do
      subject do
        tracker.enter(item_a)
        tracker.enter(item_b)
        tracker.exit(item_b)
        tracker.enter(item_c)
      end

      it_behaves_like 'a null dependency tracker'

      it 'changes predecessors of item A' do
        expect { subject }.to change { store.objects_causing_outdatedness_of(item_a) }
          .from([]).to([item_b, item_c])
      end

      it 'changes successors of item B' do
        expect { subject }.to change { store.objects_outdated_due_to(item_b) }
          .from([]).to([item_a])
      end

      it 'changes successors of item C' do
        expect { subject }.to change { store.objects_outdated_due_to(item_c) }
          .from([]).to([item_a])
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_c) }
      end

      example do
        expect { subject }.not_to change { store.objects_outdated_due_to(item_a) }
      end
    end

    context 'enter + bounce + enter' do
      subject do
        tracker.enter(item_a)
        tracker.bounce(item_b)
        tracker.enter(item_c)
      end

      it_behaves_like 'a null dependency tracker'

      it 'changes predecessors of item A' do
        expect { subject }.to change { store.objects_causing_outdatedness_of(item_a) }
          .from([]).to([item_b, item_c])
      end

      it 'changes successors of item B' do
        expect { subject }.to change { store.objects_outdated_due_to(item_b) }
          .from([]).to([item_a])
      end

      it 'changes successors of item C' do
        expect { subject }.to change { store.objects_outdated_due_to(item_c) }
          .from([]).to([item_a])
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_c) }
      end

      example do
        expect { subject }.not_to change { store.objects_outdated_due_to(item_a) }
      end
    end
  end
end
