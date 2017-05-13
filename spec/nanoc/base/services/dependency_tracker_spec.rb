# frozen_string_literal: true

describe Nanoc::Int::DependencyTracker do
  let(:tracker) { described_class.new(store) }

  let(:store) { Nanoc::Int::DependencyStore.new(empty_identifiable_collection, empty_identifiable_collection) }

  let(:item_a) { Nanoc::Int::Item.new('a', {}, '/a.md') }
  let(:item_b) { Nanoc::Int::Item.new('b', {}, '/b.md') }
  let(:item_c) { Nanoc::Int::Item.new('c', {}, '/c.md') }

  let(:empty_identifiable_collection) do
    Nanoc::Int::IdentifiableCollection.new(config)
  end

  let(:config) { Nanoc::Int::Configuration.new.with_defaults }

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
      expect { subject }.not_to change { store.dependencies_causing_outdatedness_of(item_a) }
    end

    example do
      expect { subject }.not_to change { store.dependencies_causing_outdatedness_of(item_b) }
    end

    example do
      expect { subject }.not_to change { store.dependencies_causing_outdatedness_of(item_c) }
    end
  end

  describe '#enter and #exit' do
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

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_c) }
      end
    end

    context 'enter + enter with props' do
      subject do
        tracker.enter(item_a)
        tracker.enter(item_b, compiled_content: true)
      end

      it_behaves_like 'a null dependency tracker'

      it 'changes predecessors of item A' do
        expect { subject }.to change { store.objects_causing_outdatedness_of(item_a) }
          .from([]).to([item_b])
      end

      it 'changes dependencies causing outdatedness of item A' do
        expect { subject }.to change { store.dependencies_causing_outdatedness_of(item_a).size }
          .from(0).to(1)
      end

      it 'creates correct new dependency causing outdatedness of item A' do
        subject
        dep = store.dependencies_causing_outdatedness_of(item_a)[0]

        expect(dep.from).to eql(item_b)
        expect(dep.to).to eql(item_a)
      end

      it 'creates dependency with correct props causing outdatedness of item A' do
        subject
        dep = store.dependencies_causing_outdatedness_of(item_a)[0]

        expect(dep.props.compiled_content?).to eq(true)

        expect(dep.props.raw_content?).to eq(false)
        expect(dep.props.attributes?).to eq(false)
        expect(dep.props.path?).to eq(false)
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_c) }
      end

      example do
        expect { subject }.not_to change { store.dependencies_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.dependencies_causing_outdatedness_of(item_c) }
      end
    end

    context 'enter + enter with prop + exit + enter with prop' do
      subject do
        tracker.enter(item_a)
        tracker.enter(item_b, compiled_content: true)
        tracker.exit
        tracker.enter(item_b, attributes: true)
      end

      it_behaves_like 'a null dependency tracker'

      it 'changes predecessors of item A' do
        expect { subject }.to change { store.objects_causing_outdatedness_of(item_a) }
          .from([]).to([item_b])
      end

      it 'changes dependencies causing outdatedness of item A' do
        expect { subject }.to change { store.dependencies_causing_outdatedness_of(item_a).size }
          .from(0).to(1)
      end

      it 'creates correct new dependency causing outdatedness of item A' do
        subject
        dep = store.dependencies_causing_outdatedness_of(item_a)[0]

        expect(dep.from).to eql(item_b)
        expect(dep.to).to eql(item_a)
      end

      it 'creates dependency with correct props causing outdatedness of item A' do
        subject
        dep = store.dependencies_causing_outdatedness_of(item_a)[0]

        expect(dep.props.compiled_content?).to eq(true)
        expect(dep.props.attributes?).to eq(true)

        expect(dep.props.raw_content?).to eq(false)
        expect(dep.props.path?).to eq(false)
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_c) }
      end

      example do
        expect { subject }.not_to change { store.dependencies_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.dependencies_causing_outdatedness_of(item_c) }
      end
    end

    context 'enter + enter + exit + enter' do
      subject do
        tracker.enter(item_a)
        tracker.enter(item_b)
        tracker.exit
        tracker.enter(item_c)
      end

      it_behaves_like 'a null dependency tracker'

      it 'changes predecessors of item A' do
        expect { subject }.to change { store.objects_causing_outdatedness_of(item_a) }
          .from([]).to([item_b, item_c])
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_c) }
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

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_b) }
      end

      example do
        expect { subject }.not_to change { store.objects_causing_outdatedness_of(item_c) }
      end
    end
  end
end
