# frozen_string_literal: true

describe Nanoc::Core::DependencyStore do
  let(:store) { described_class.new(items, layouts, config) }

  let(:item_a) { Nanoc::Core::Item.new('a', {}, '/a.md') }
  let(:item_b) { Nanoc::Core::Item.new('b', {}, '/b.md') }
  let(:item_c) { Nanoc::Core::Item.new('c', {}, '/c.md') }

  let(:layout_a) { Nanoc::Core::Layout.new('la', {}, '/la.md') }
  let(:layout_b) { Nanoc::Core::Layout.new('lb', {}, '/lb.md') }

  let(:items) { Nanoc::Core::ItemCollection.new(config, [item_a, item_b, item_c]) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config, [layout_a, layout_b]) }
  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  it 'is empty by default' do
    expect(store.objects_causing_outdatedness_of(item_a)).to be_empty
    expect(store.objects_causing_outdatedness_of(item_b)).to be_empty
    expect(store.objects_causing_outdatedness_of(item_c)).to be_empty
    expect(store.objects_causing_outdatedness_of(layout_a)).to be_empty
    expect(store.objects_causing_outdatedness_of(layout_b)).to be_empty
  end

  describe '#dependencies_causing_outdatedness_of' do
    context 'no dependencies' do
      it 'returns nothing for each' do
        expect(store.dependencies_causing_outdatedness_of(item_a)).to be_empty
        expect(store.dependencies_causing_outdatedness_of(item_b)).to be_empty
        expect(store.dependencies_causing_outdatedness_of(item_c)).to be_empty
      end
    end

    context 'one dependency' do
      context 'dependency on config, no props' do
        before do
          store.record_dependency(item_a, config)
        end

        it 'returns one dependency' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps.size).to be(1)
        end

        it 'returns dependency from a onto config' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].from).to eql(config)
          expect(deps[0].to).to eql(item_a)
        end

        it 'returns nothing for the others' do
          expect(store.dependencies_causing_outdatedness_of(item_b)).to be_empty
          expect(store.dependencies_causing_outdatedness_of(item_c)).to be_empty
        end
      end

      context 'dependency on config, generic attributes prop' do
        before do
          store.record_dependency(item_a, config, attributes: true)
        end

        it 'returns false for all unspecified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.raw_content?).to be(false)
          expect(deps[0].props.compiled_content?).to be(false)
          expect(deps[0].props.path?).to be(false)
        end

        it 'returns the specified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.attributes?).to be(true)
        end
      end

      context 'dependency on config, specific attributes prop' do
        before do
          store.record_dependency(item_a, config, attributes: [:donkey])
        end

        it 'returns false for all unspecified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.raw_content?).to be(false)
          expect(deps[0].props.compiled_content?).to be(false)
          expect(deps[0].props.path?).to be(false)
        end

        it 'returns the specified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.attributes?).to be(true)
          expect(deps[0].props.attributes).to contain_exactly(:donkey)
        end
      end

      context 'dependency on items, generic prop' do
        before do
          store.record_dependency(item_a, items)
        end

        it 'creates one dependency' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps.size).to be(1)
        end
      end

      context 'no props' do
        before do
          store.record_dependency(item_a, item_b)
        end

        it 'returns one dependency' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps.size).to be(1)
        end

        it 'returns dependency from b to a' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].from).to eql(item_b)
          expect(deps[0].to).to eql(item_a)
        end

        it 'returns nothing for the others' do
          expect(store.dependencies_causing_outdatedness_of(item_b)).to be_empty
          expect(store.dependencies_causing_outdatedness_of(item_c)).to be_empty
        end
      end

      context 'dependency on item that will be removed' do
        before do
          store.record_dependency(item_a, item_b)
          store.items = Nanoc::Core::ItemCollection.new(config, [item_a])
        end

        it 'retains dependency, but from nil' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps.size).to be(1)
          expect(deps[0].from).to be_nil
          expect(deps[0].to).to eql(item_a)
        end
      end

      context 'one prop' do
        before do
          store.record_dependency(item_a, item_b, compiled_content: true)
        end

        it 'returns false for all unspecified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.raw_content?).to be(false)
          expect(deps[0].props.attributes?).to be(false)
          expect(deps[0].props.path?).to be(false)
        end

        it 'returns the specified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.compiled_content?).to be(true)
        end
      end

      context 'two props' do
        before do
          store.record_dependency(item_a, item_b, compiled_content: true)
          store.record_dependency(item_a, item_b, attributes: true)
        end

        it 'returns false for all unspecified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.raw_content?).to be(false)
          expect(deps[0].props.path?).to be(false)
        end

        it 'returns the specified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.attributes?).to be(true)
          expect(deps[0].props.compiled_content?).to be(true)
        end
      end
    end

    context 'two dependency in a chain' do
      before do
        store.record_dependency(item_a, item_b)
        store.record_dependency(item_b, item_c)
      end

      it 'returns one dependency for object A' do
        deps = store.dependencies_causing_outdatedness_of(item_a)
        expect(deps.size).to be(1)
        expect(deps[0].from).to eql(item_b)
      end

      it 'returns one dependency for object B' do
        deps = store.dependencies_causing_outdatedness_of(item_b)
        expect(deps.size).to be(1)
        expect(deps[0].from).to eql(item_c)
      end

      it 'returns nothing for the others' do
        expect(store.dependencies_causing_outdatedness_of(item_c)).to be_empty
      end
    end
  end

  describe 'reloading - item a -> b' do
    before do
      store.record_dependency(item_a, item_b, compiled_content: true)
      store.record_dependency(item_a, item_b, attributes: true)

      store.store
    end

    let(:reloaded_store) do
      described_class.new(items_after, layouts, config).tap(&:load)
    end

    context 'no new items' do
      let(:items_after) { items }

      it 'has the right dependencies for item A' do
        deps = reloaded_store.dependencies_causing_outdatedness_of(item_a)
        expect(deps.size).to be(1)

        expect(deps[0].from).to eql(item_b)
        expect(deps[0].to).to eql(item_a)

        expect(deps[0].props.raw_content?).to be(false)
        expect(deps[0].props.attributes?).to be(true)
        expect(deps[0].props.compiled_content?).to be(true)
        expect(deps[0].props.path?).to be(false)
      end

      it 'has the right dependencies for item B' do
        deps = reloaded_store.dependencies_causing_outdatedness_of(item_b)
        expect(deps).to be_empty
      end

      it 'has the right dependencies for item C' do
        deps = reloaded_store.dependencies_causing_outdatedness_of(item_c)
        expect(deps).to be_empty
      end

      it 'has no new items' do
        expect(reloaded_store.new_items).to be_empty
      end

      it 'has no new layouts' do
        expect(reloaded_store.new_layouts).to be_empty
      end
    end

    context 'one new item' do
      let(:items_after) do
        Nanoc::Core::ItemCollection.new(config, [item_a, item_b, item_c, item_d])
      end

      let(:item_d) { Nanoc::Core::Item.new('d', {}, '/d.md') }

      it 'does not mark items as outdated' do
        expect(reloaded_store.objects_causing_outdatedness_of(item_a)).not_to include(item_d)
        expect(reloaded_store.objects_causing_outdatedness_of(item_b)).not_to include(item_d)
        expect(reloaded_store.objects_causing_outdatedness_of(item_c)).not_to include(item_d)
        expect(reloaded_store.objects_causing_outdatedness_of(item_d)).not_to include(item_d)
      end

      it 'has one new item' do
        expect(reloaded_store.new_items).to contain_exactly(item_d)
      end

      it 'has no new layouts' do
        expect(reloaded_store.new_layouts).to be_empty
      end
    end

    context 'unrelated item removed' do
      let(:items_after) do
        Nanoc::Core::ItemCollection.new(config, [item_a, item_b])
      end

      it 'does not mark items as outdated' do
        expect(reloaded_store.objects_causing_outdatedness_of(item_a)).to eq([item_b])
        expect(reloaded_store.objects_causing_outdatedness_of(item_b)).to be_empty
        expect(reloaded_store.objects_causing_outdatedness_of(item_c)).to be_empty
      end
    end

    context 'related item removed' do
      let(:items_after) do
        Nanoc::Core::ItemCollection.new(config, [item_a, item_c])
      end

      it 'does not mark items as outdated' do
        expect(reloaded_store.objects_causing_outdatedness_of(item_a)).to eq([nil])
        expect(reloaded_store.objects_causing_outdatedness_of(item_b)).to be_empty
        expect(reloaded_store.objects_causing_outdatedness_of(item_c)).to be_empty
      end
    end
  end

  describe 'reloading - item a -> config' do
    before do
      store.record_dependency(item_a, config, attributes: [:donkey])

      store.store
      store.load
    end

    it 'has the right dependencies for item A' do
      deps = store.dependencies_causing_outdatedness_of(item_a)
      expect(deps.size).to be(1)

      expect(deps[0].from).to eql(config)
      expect(deps[0].to).to eql(item_a)

      expect(deps[0].props.raw_content?).to be(false)
      expect(deps[0].props.attributes?).to be(true)
      expect(deps[0].props.attributes).to contain_exactly(:donkey)
      expect(deps[0].props.compiled_content?).to be(false)
      expect(deps[0].props.path?).to be(false)
    end

    it 'has the right dependencies for item B' do
      deps = store.dependencies_causing_outdatedness_of(item_b)
      expect(deps).to be_empty
    end

    it 'has the right dependencies for item C' do
      deps = store.dependencies_causing_outdatedness_of(item_c)
      expect(deps).to be_empty
    end
  end

  shared_examples 'records dependencies' do
    context 'no props' do
      subject { store.record_dependency(source_obj, item_b) }

      it 'records a dependency' do
        expect { subject }
          .to change { store.objects_causing_outdatedness_of(source_obj) }
          .from([])
          .to([item_b])
      end

      it 'ignores all other objects' do
        subject
        expect(other_items).to all(satisfy { |o| store.dependencies_causing_outdatedness_of(o).empty? })
      end

      context 'dependency on self' do
        subject { store.record_dependency(source_obj, item_a) }

        it 'does not create dependency on self' do
          expect { subject }
            .not_to change { store.objects_causing_outdatedness_of(source_obj) }
        end
      end

      context 'two dependencies' do
        subject do
          store.record_dependency(source_obj, item_b)
          store.record_dependency(source_obj, item_b)
        end

        it 'does not create duplicate dependencies' do
          expect { subject }
            .to change { store.objects_causing_outdatedness_of(source_obj) }
            .from([])
            .to([item_b])
        end
      end

      context 'dependency to nil' do
        subject { store.record_dependency(source_obj, nil) }

        it 'creates a dependency to nil' do
          expect { subject }
            .to change { store.objects_causing_outdatedness_of(source_obj) }
            .from([])
            .to([nil])
        end
      end

      context 'dependency from nil' do
        subject { store.record_dependency(nil, item_b) }

        it 'does not create a dependency from nil' do
          expect { subject }
            .not_to change { store.objects_causing_outdatedness_of(item_b) }
        end
      end
    end

    context 'compiled content prop' do
      subject { store.record_dependency(source_obj, target_obj, compiled_content: true) }

      it 'records a dependency' do
        expect { subject }
          .to change { store.objects_causing_outdatedness_of(source_obj) }
          .from([])
          .to([target_obj])
      end

      it 'records a dependency with the right props' do
        subject
        deps = store.dependencies_causing_outdatedness_of(source_obj)

        expect(deps.first.props.attributes?).to be(false)
        expect(deps.first.props.compiled_content?).to be(true)
      end

      it 'ignores all other objects' do
        subject
        expect(other_items).to all(satisfy { |o| store.dependencies_causing_outdatedness_of(o).empty? })
      end
    end

    context 'attribute prop (true)' do
      subject { store.record_dependency(source_obj, target_obj, attributes: true) }

      it 'records a dependency' do
        expect { subject }
          .to change { store.objects_causing_outdatedness_of(source_obj) }
          .from([])
          .to([target_obj])
      end

      it 'records a dependency with the right props' do
        subject
        deps = store.dependencies_causing_outdatedness_of(source_obj)

        expect(deps.first.props.attributes?).to be(true)
        expect(deps.first.props.attributes).to be(true)
        expect(deps.first.props.compiled_content?).to be(false)
      end

      it 'ignores all other objects' do
        subject
        expect(other_items).to all(satisfy { |o| store.dependencies_causing_outdatedness_of(o).empty? })
      end
    end

    context 'attribute prop (true)' do
      subject { store.record_dependency(source_obj, target_obj, attributes: [:giraffe]) }

      it 'records a dependency' do
        expect { subject }
          .to change { store.objects_causing_outdatedness_of(source_obj) }
          .from([])
          .to([target_obj])
      end

      it 'records a dependency with the right props' do
        subject
        deps = store.dependencies_causing_outdatedness_of(source_obj)

        expect(deps.first.props.attributes?).to be(true)
        expect(deps.first.props.attributes).to contain_exactly(:giraffe)
        expect(deps.first.props.compiled_content?).to be(false)
      end

      it 'ignores all other objects' do
        subject
        expect(other_items).to all(satisfy { |o| store.dependencies_causing_outdatedness_of(o).empty? })
      end
    end
  end

  describe '#record_dependency' do
    context 'item on item' do
      let(:source_obj) { item_a }
      let(:target_obj) { item_b }
      let(:other_items) { [item_c] }

      include_examples 'records dependencies'
    end

    context 'item on layout' do
      let(:source_obj) { item_a }
      let(:target_obj) { layout_a }
      let(:other_items) { [item_b, item_c] }

      include_examples 'records dependencies'
    end

    context 'item on config' do
      let(:source_obj) { item_a }
      let(:target_obj) { config }
      let(:other_items) { [item_b, item_c] }

      include_examples 'records dependencies'
    end
  end

  describe '#forget_dependencies_for' do
    subject { store.forget_dependencies_for(item_b) }

    before do
      store.record_dependency(item_a, item_b)
      store.record_dependency(item_a, item_c)
      store.record_dependency(item_b, item_a)
      store.record_dependency(item_b, item_c)
      store.record_dependency(item_c, item_a)
      store.record_dependency(item_c, item_b)
    end

    it 'removes dependencies from item_a' do
      expect { subject }
        .not_to change { store.objects_causing_outdatedness_of(item_a) }
    end

    it 'removes dependencies from item_b' do
      expect { subject }
        .to change { store.objects_causing_outdatedness_of(item_b) }
        .from(contain_exactly(item_a, item_c))
        .to(be_empty)
    end

    it 'removes dependencies from item_c' do
      expect { subject }
        .not_to change { store.objects_causing_outdatedness_of(item_c) }
    end
  end
end
