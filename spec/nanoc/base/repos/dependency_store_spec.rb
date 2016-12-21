describe Nanoc::Int::DependencyStore do
  let(:store) { described_class.new(objects) }

  let(:objects) do
    [obj_a, obj_b, obj_c]
  end

  let(:obj_a) { Nanoc::Int::Item.new('a', {}, '/a.md') }
  let(:obj_b) { Nanoc::Int::Item.new('b', {}, '/b.md') }
  let(:obj_c) { Nanoc::Int::Item.new('c', {}, '/c.md') }

  describe '#dependencies_causing_outdatedness_of' do
    context 'no dependencies' do
      it 'returns nothing for each' do
        expect(store.dependencies_causing_outdatedness_of(obj_a)).to be_empty
        expect(store.dependencies_causing_outdatedness_of(obj_b)).to be_empty
        expect(store.dependencies_causing_outdatedness_of(obj_c)).to be_empty
      end
    end

    context 'one dependency' do
      context 'no props' do
        before do
          # FIXME: weird argument order (obj_b depends on obj_a, not th other way around)
          store.record_dependency(obj_a, obj_b)
        end

        it 'returns one dependency' do
          deps = store.dependencies_causing_outdatedness_of(obj_a)
          expect(deps.size).to eql(1)
        end

        it 'returns dependency from b to a' do
          deps = store.dependencies_causing_outdatedness_of(obj_a)
          expect(deps[0].from).to eql(obj_b)
          expect(deps[0].to).to eql(obj_a)
        end

        it 'returns true for all props by default' do
          deps = store.dependencies_causing_outdatedness_of(obj_a)
          expect(deps[0].props.raw_content?).to eq(true)
          expect(deps[0].props.attributes?).to eq(true)
          expect(deps[0].props.compiled_content?).to eq(true)
          expect(deps[0].props.path?).to eq(true)
        end

        it 'returns nothing for the others' do
          expect(store.dependencies_causing_outdatedness_of(obj_b)).to be_empty
          expect(store.dependencies_causing_outdatedness_of(obj_c)).to be_empty
        end
      end

      context 'one prop' do
        before do
          # FIXME: weird argument order (obj_b depends on obj_a, not th other way around)
          store.record_dependency(obj_a, obj_b, compiled_content: true)
        end

        it 'returns false for all unspecified props' do
          deps = store.dependencies_causing_outdatedness_of(obj_a)
          expect(deps[0].props.raw_content?).to eq(false)
          expect(deps[0].props.attributes?).to eq(false)
          expect(deps[0].props.path?).to eq(false)
        end

        it 'returns the specified props' do
          deps = store.dependencies_causing_outdatedness_of(obj_a)
          expect(deps[0].props.compiled_content?).to eq(true)
        end
      end

      context 'two props' do
        before do
          # FIXME: weird argument order (obj_b depends on obj_a, not th other way around)
          store.record_dependency(obj_a, obj_b, compiled_content: true)
          store.record_dependency(obj_a, obj_b, attributes: true)
        end

        it 'returns false for all unspecified props' do
          deps = store.dependencies_causing_outdatedness_of(obj_a)
          expect(deps[0].props.raw_content?).to eq(false)
          expect(deps[0].props.path?).to eq(false)
        end

        it 'returns the specified props' do
          deps = store.dependencies_causing_outdatedness_of(obj_a)
          expect(deps[0].props.attributes?).to eq(true)
          expect(deps[0].props.compiled_content?).to eq(true)
        end
      end
    end

    context 'two dependency in a chain' do
      before do
        # FIXME: weird argument order (obj_b depends on obj_a, not th other way around)
        store.record_dependency(obj_a, obj_b)
        store.record_dependency(obj_b, obj_c)
      end

      it 'returns one dependency for object A' do
        deps = store.dependencies_causing_outdatedness_of(obj_a)
        expect(deps.size).to eql(1)
        expect(deps[0].from).to eql(obj_b)
      end

      it 'returns one dependency for object B' do
        deps = store.dependencies_causing_outdatedness_of(obj_b)
        expect(deps.size).to eql(1)
        expect(deps[0].from).to eql(obj_c)
      end

      it 'returns nothing for the others' do
        expect(store.dependencies_causing_outdatedness_of(obj_c)).to be_empty
      end
    end
  end

  describe 'reloading' do
    before do
      store.record_dependency(obj_a, obj_b, compiled_content: true)
      store.record_dependency(obj_a, obj_b, attributes: true)

      store.store
      store.objects = objects_after
      store.load
    end

    context 'no new objects' do
      let(:objects_after) { objects }

      it 'has the right dependencies for item A' do
        deps = store.dependencies_causing_outdatedness_of(obj_a)
        expect(deps.size).to eql(1)

        expect(deps[0].from).to eql(obj_b)
        expect(deps[0].to).to eql(obj_a)

        expect(deps[0].props.raw_content?).to eq(false)
        expect(deps[0].props.attributes?).to eq(true)
        expect(deps[0].props.compiled_content?).to eq(true)
        expect(deps[0].props.path?).to eq(false)
      end

      it 'has the right dependencies for item B' do
        deps = store.dependencies_causing_outdatedness_of(obj_b)
        expect(deps).to be_empty
      end

      it 'has the right dependencies for item C' do
        deps = store.dependencies_causing_outdatedness_of(obj_c)
        expect(deps).to be_empty
      end
    end

    context 'one new object' do
      let(:objects_after) do
        [obj_a, obj_b, obj_c, obj_d]
      end

      let(:obj_d) { Nanoc::Int::Item.new('d', {}, '/d.md') }

      it 'marks existing items as outdated' do
        expect(store.objects_causing_outdatedness_of(obj_a)).to eq([obj_d])
        expect(store.objects_causing_outdatedness_of(obj_b)).to eq([obj_d])
        expect(store.objects_causing_outdatedness_of(obj_c)).to eq([obj_d])
      end

      it 'marks new items as outdated' do
        expect(store.objects_causing_outdatedness_of(obj_d)).to eq([obj_d])
      end
    end

    context 'two new objects' do
      let(:objects_after) do
        [obj_a, obj_b, obj_c, obj_d, obj_e]
      end

      let(:obj_d) { Nanoc::Int::Item.new('d', {}, '/d.md') }
      let(:obj_e) { Nanoc::Int::Item.new('e', {}, '/e.md') }

      it 'marks existing items as outdated' do
        # Only one of obj D or E needed!
        expect(store.objects_causing_outdatedness_of(obj_a)).to eq([obj_d]).or eq([obj_e])
        expect(store.objects_causing_outdatedness_of(obj_b)).to eq([obj_d]).or eq([obj_e])
        expect(store.objects_causing_outdatedness_of(obj_c)).to eq([obj_d]).or eq([obj_e])
      end

      it 'marks new items as outdated' do
        # Only one of obj D or E needed!
        expect(store.objects_causing_outdatedness_of(obj_d)).to eq([obj_d]).or eq([obj_e])
        expect(store.objects_causing_outdatedness_of(obj_e)).to eq([obj_d]).or eq([obj_e])
      end
    end
  end
end
