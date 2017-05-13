# frozen_string_literal: true

describe Nanoc::Helpers::ChildParent, helper: true do
  describe '#children_of' do
    subject { helper.children_of(item) }

    before { ctx.create_item('some content', {}, identifier) }
    let(:item) { ctx.items[identifier] }

    context 'legacy identifier' do
      let(:identifier) { Nanoc::Identifier.new('/foo/', type: :legacy) }

      before do
        ctx.create_item('abc', {}, Nanoc::Identifier.new('/foo/a/', type: :legacy))
        ctx.create_item('def', {}, Nanoc::Identifier.new('/foo/a/b/', type: :legacy))
        ctx.create_item('xyz', {}, Nanoc::Identifier.new('/bar/', type: :legacy))
      end

      it 'returns only direct children' do
        expect(subject).to eql([ctx.items['/foo/a/']])
      end
    end

    context 'full identifier' do
      let(:identifier) { Nanoc::Identifier.new('/foo.md', type: :full) }

      before do
        ctx.create_item('abc', {}, Nanoc::Identifier.new('/foo/a.md', type: :full))
        ctx.create_item('def', {}, Nanoc::Identifier.new('/foo/a/b.md', type: :full))
        ctx.create_item('xyz', {}, Nanoc::Identifier.new('/bar.md', type: :full))
        ctx.create_item('xyz', {}, Nanoc::Identifier.new('/foo/a/index.md', type: :full))
      end

      it 'returns only direct children' do
        expect(subject).to eql([ctx.items['/foo/a.md']])
      end
    end
  end

  describe '#parent_of' do
    subject { helper.parent_of(item) }

    before { ctx.create_item('some content', {}, identifier) }
    let(:item) { ctx.items[identifier] }

    context 'legacy identifier' do
      let(:identifier) { Nanoc::Identifier.new('/foo/bar/', type: :legacy) }

      before do
        ctx.create_item('abc', {}, Nanoc::Identifier.new('/foo/', type: :legacy))
        ctx.create_item('def', {}, Nanoc::Identifier.new('/foo/qux/', type: :legacy))
        ctx.create_item('xyz', {}, Nanoc::Identifier.new('/foo/bar/asdf/', type: :legacy))
        ctx.create_item('opq', {}, Nanoc::Identifier.new('/', type: :legacy))
      end

      it 'returns parent' do
        expect(subject).to eql(ctx.items['/foo/'])
      end
    end

    context 'full identifier' do
      let(:identifier) { Nanoc::Identifier.new('/foo/bar.md', type: :full) }

      before do
        ctx.create_item('abc', {}, Nanoc::Identifier.new('/foo.md', type: :full))
        ctx.create_item('def', {}, Nanoc::Identifier.new('/foo/qux.md', type: :full))
        ctx.create_item('xyz', {}, Nanoc::Identifier.new('/foo/bar/asdf.md', type: :full))
        ctx.create_item('opq', {}, Nanoc::Identifier.new('/index.md', type: :full))
      end

      it 'returns parent' do
        expect(subject).to eql(ctx.items['/foo.md'])
      end
    end
  end
end
