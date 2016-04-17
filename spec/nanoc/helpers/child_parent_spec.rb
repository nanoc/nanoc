describe Nanoc::Helpers::ChildParent, helper: true do
  describe '#children_of' do
    subject { helper.children_of(item) }

    let(:item) { ctx.create_item('some content', {}, identifier) }

    context 'legacy identifier' do
      let(:identifier) { Nanoc::Identifier.new('/foo/', type: :legacy) }

      let!(:child_item) do
        ctx.create_item('abc', {}, Nanoc::Identifier.new('/foo/a/', type: :legacy))
      end

      let!(:grandchild_item) do
        ctx.create_item('def', {}, Nanoc::Identifier.new('/foo/a/b/', type: :legacy))
      end

      let!(:sibling_item) do
        ctx.create_item('xyz', {}, Nanoc::Identifier.new('/bar/', type: :legacy))
      end

      it 'returns only direct children' do
        expect(subject).to eql([child_item])
      end
    end

    context 'full identifier' do
      let(:identifier) { Nanoc::Identifier.new('/foo.md', type: :full) }

      let!(:child_item) do
        ctx.create_item('abc', {}, Nanoc::Identifier.new('/foo/a.md', type: :full))
      end

      let!(:grandchild_item) do
        ctx.create_item('def', {}, Nanoc::Identifier.new('/foo/a/b.md', type: :full))
      end

      let!(:sibling_item) do
        ctx.create_item('xyz', {}, Nanoc::Identifier.new('/bar.md', type: :full))
      end

      let!(:index_child_item) do
        ctx.create_item('xyz', {}, Nanoc::Identifier.new('/foo/a/index.md', type: :full))
      end

      it 'returns only direct children' do
        expect(subject).to eql([child_item])
      end
    end
  end

  describe '#parent_of' do
    subject { helper.parent_of(item) }

    let(:item) { ctx.create_item('some content', {}, identifier) }

    context 'legacy identifier' do
      let(:identifier) { Nanoc::Identifier.new('/foo/bar/', type: :legacy) }

      let!(:parent_item) do
        ctx.create_item('abc', {}, Nanoc::Identifier.new('/foo/', type: :legacy))
      end

      let!(:sibling_item) do
        ctx.create_item('def', {}, Nanoc::Identifier.new('/foo/qux/', type: :legacy))
      end

      let!(:child_item) do
        ctx.create_item('xyz', {}, Nanoc::Identifier.new('/foo/bar/asdf/', type: :legacy))
      end

      let!(:grandparent_item) do
        ctx.create_item('opq', {}, Nanoc::Identifier.new('/', type: :legacy))
      end

      it 'returns parent' do
        expect(subject).to eql(parent_item)
      end
    end

    context 'full identifier' do
      let(:identifier) { Nanoc::Identifier.new('/foo/bar.md', type: :full) }

      let!(:parent_item) do
        ctx.create_item('abc', {}, Nanoc::Identifier.new('/foo.md', type: :full))
      end

      let!(:sibling_item) do
        ctx.create_item('def', {}, Nanoc::Identifier.new('/foo/qux.md', type: :full))
      end

      let!(:child_item) do
        ctx.create_item('xyz', {}, Nanoc::Identifier.new('/foo/bar/asdf.md', type: :full))
      end

      let!(:grandparent_item) do
        ctx.create_item('opq', {}, Nanoc::Identifier.new('/index.md', type: :full))
      end

      it 'returns parent' do
        expect(subject).to eql(parent_item)
      end
    end
  end
end
