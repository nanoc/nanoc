# frozen_string_literal: true

describe Nanoc::Int::DependencyStore do
  let(:store) { described_class.new(items, layouts) }

  let(:item_a) { Nanoc::Int::Item.new('a', {}, '/a.md') }
  let(:item_b) { Nanoc::Int::Item.new('b', {}, '/b.md') }
  let(:item_c) { Nanoc::Int::Item.new('c', {}, '/c.md') }

  let(:items) { Nanoc::Int::IdentifiableCollection.new(config, [item_a, item_b, item_c]) }
  let(:layouts) { Nanoc::Int::IdentifiableCollection.new(config) }
  let(:config) { Nanoc::Int::Configuration.new }

  describe '#dependencies_causing_outdatedness_of' do
    context 'no dependencies' do
      it 'returns nothing for each' do
        expect(store.dependencies_causing_outdatedness_of(item_a)).to be_empty
        expect(store.dependencies_causing_outdatedness_of(item_b)).to be_empty
        expect(store.dependencies_causing_outdatedness_of(item_c)).to be_empty
      end
    end

    context 'one dependency' do
      context 'no props' do
        before do
          # FIXME: weird argument order (item_b depends on item_a, not th other way around)
          store.record_dependency(item_a, item_b)
        end

        it 'returns one dependency' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps.size).to eql(1)
        end

        it 'returns dependency from b to a' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].from).to eql(item_b)
          expect(deps[0].to).to eql(item_a)
        end

        it 'returns true for all props by default' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.raw_content?).to eq(true)
          expect(deps[0].props.attributes?).to eq(true)
          expect(deps[0].props.compiled_content?).to eq(true)
          expect(deps[0].props.path?).to eq(true)
        end

        it 'returns nothing for the others' do
          expect(store.dependencies_causing_outdatedness_of(item_b)).to be_empty
          expect(store.dependencies_causing_outdatedness_of(item_c)).to be_empty
        end
      end

      context 'one prop' do
        before do
          # FIXME: weird argument order (item_b depends on item_a, not th other way around)
          store.record_dependency(item_a, item_b, compiled_content: true)
        end

        it 'returns false for all unspecified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.raw_content?).to eq(false)
          expect(deps[0].props.attributes?).to eq(false)
          expect(deps[0].props.path?).to eq(false)
        end

        it 'returns the specified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.compiled_content?).to eq(true)
        end
      end

      context 'two props' do
        before do
          # FIXME: weird argument order (item_b depends on item_a, not th other way around)
          store.record_dependency(item_a, item_b, compiled_content: true)
          store.record_dependency(item_a, item_b, attributes: true)
        end

        it 'returns false for all unspecified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.raw_content?).to eq(false)
          expect(deps[0].props.path?).to eq(false)
        end

        it 'returns the specified props' do
          deps = store.dependencies_causing_outdatedness_of(item_a)
          expect(deps[0].props.attributes?).to eq(true)
          expect(deps[0].props.compiled_content?).to eq(true)
        end
      end
    end

    context 'two dependency in a chain' do
      before do
        # FIXME: weird argument order (item_b depends on item_a, not th other way around)
        store.record_dependency(item_a, item_b)
        store.record_dependency(item_b, item_c)
      end

      it 'returns one dependency for object A' do
        deps = store.dependencies_causing_outdatedness_of(item_a)
        expect(deps.size).to eql(1)
        expect(deps[0].from).to eql(item_b)
      end

      it 'returns one dependency for object B' do
        deps = store.dependencies_causing_outdatedness_of(item_b)
        expect(deps.size).to eql(1)
        expect(deps[0].from).to eql(item_c)
      end

      it 'returns nothing for the others' do
        expect(store.dependencies_causing_outdatedness_of(item_c)).to be_empty
      end
    end
  end

  describe 'reloading' do
    before do
      store.record_dependency(item_a, item_b, compiled_content: true)
      store.record_dependency(item_a, item_b, attributes: true)

      store.store
      store.items = items_after
      store.load
    end

    context 'no new items' do
      let(:items_after) { items }

      it 'has the right dependencies for item A' do
        deps = store.dependencies_causing_outdatedness_of(item_a)
        expect(deps.size).to eql(1)

        expect(deps[0].from).to eql(item_b)
        expect(deps[0].to).to eql(item_a)

        expect(deps[0].props.raw_content?).to eq(false)
        expect(deps[0].props.attributes?).to eq(true)
        expect(deps[0].props.compiled_content?).to eq(true)
        expect(deps[0].props.path?).to eq(false)
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

    context 'one new item' do
      let(:items_after) do
        Nanoc::Int::IdentifiableCollection.new(config, [item_a, item_b, item_c, item_d])
      end

      let(:item_d) { Nanoc::Int::Item.new('d', {}, '/d.md') }

      it 'marks existing items as outdated' do
        expect(store.objects_causing_outdatedness_of(item_a)).to eq([item_d])
        expect(store.objects_causing_outdatedness_of(item_b)).to eq([item_d])
        expect(store.objects_causing_outdatedness_of(item_c)).to eq([item_d])
      end

      it 'marks new items as outdated' do
        expect(store.objects_causing_outdatedness_of(item_d)).to eq([item_d])
      end
    end

    context 'two new items' do
      let(:items_after) do
        Nanoc::Int::IdentifiableCollection.new(config, [item_a, item_b, item_c, item_d, item_e])
      end

      let(:item_d) { Nanoc::Int::Item.new('d', {}, '/d.md') }
      let(:item_e) { Nanoc::Int::Item.new('e', {}, '/e.md') }

      it 'marks existing items as outdated' do
        # Only one of obj D or E needed!
        expect(store.objects_causing_outdatedness_of(item_a)).to eq([item_d]).or eq([item_e])
        expect(store.objects_causing_outdatedness_of(item_b)).to eq([item_d]).or eq([item_e])
        expect(store.objects_causing_outdatedness_of(item_c)).to eq([item_d]).or eq([item_e])
      end

      it 'marks new items as outdated' do
        # Only one of obj D or E needed!
        expect(store.objects_causing_outdatedness_of(item_d)).to eq([item_d]).or eq([item_e])
        expect(store.objects_causing_outdatedness_of(item_e)).to eq([item_d]).or eq([item_e])
      end
    end
  end

  describe '#record_dependency' do
    context 'no props' do
      subject { store.record_dependency(item_a, item_b) }

      it 'records a dependency' do
        expect { subject }
          .to change { store.objects_causing_outdatedness_of(item_a) }
          .from([])
          .to([item_b])
      end
    end

    context 'compiled content prop' do
      subject { store.record_dependency(item_a, item_b, compiled_content: true) }

      it 'records a dependency' do
        expect { subject }
          .to change { store.objects_causing_outdatedness_of(item_a) }
          .from([])
          .to([item_b])
      end

      it 'records a dependency with the right props' do
        subject
        deps = store.dependencies_causing_outdatedness_of(item_a)

        expect(deps.first.props.attributes?).not_to be
        expect(deps.first.props.compiled_content?).to be
      end
    end

    context 'attribute prop (true)' do
      subject { store.record_dependency(item_a, item_b, attributes: true) }

      it 'records a dependency' do
        expect { subject }
          .to change { store.objects_causing_outdatedness_of(item_a) }
          .from([])
          .to([item_b])
      end

      it 'records a dependency with the right props' do
        subject
        deps = store.dependencies_causing_outdatedness_of(item_a)

        expect(deps.first.props.attributes?).to be
        expect(deps.first.props.attributes).to be
        expect(deps.first.props.compiled_content?).not_to be
      end
    end

    context 'attribute prop (true)' do
      subject { store.record_dependency(item_a, item_b, attributes: [:giraffe]) }

      it 'records a dependency' do
        expect { subject }
          .to change { store.objects_causing_outdatedness_of(item_a) }
          .from([])
          .to([item_b])
      end

      it 'records a dependency with the right props' do
        subject
        deps = store.dependencies_causing_outdatedness_of(item_a)

        expect(deps.first.props.attributes?).to be
        expect(deps.first.props.attributes).to match_array([:giraffe])
        expect(deps.first.props.compiled_content?).not_to be
      end
    end
  end
end
