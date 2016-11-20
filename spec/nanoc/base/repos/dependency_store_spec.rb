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

        it 'returns false for all props by default' do
          deps = store.dependencies_causing_outdatedness_of(obj_a)
          expect(deps[0].raw_content?).to eq(false)
          expect(deps[0].attributes?).to eq(false)
          expect(deps[0].compiled_content?).to eq(false)
          expect(deps[0].path?).to eq(false)
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
          expect(deps[0].raw_content?).to eq(false)
          expect(deps[0].attributes?).to eq(false)
          expect(deps[0].path?).to eq(false)
        end

        it 'returns the specified props' do
          deps = store.dependencies_causing_outdatedness_of(obj_a)
          expect(deps[0].compiled_content?).to eq(true)
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
          expect(deps[0].raw_content?).to eq(false)
          expect(deps[0].path?).to eq(false)
        end

        it 'returns the specified props' do
          deps = store.dependencies_causing_outdatedness_of(obj_a)
          expect(deps[0].attributes?).to eq(true)
          expect(deps[0].compiled_content?).to eq(true)
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
end
