# frozen_string_literal: true

describe Nanoc::Helpers::Breadcrumbs, helper: true do
  before do
    allow(ctx.dependency_tracker).to receive(:enter)
    allow(ctx.dependency_tracker).to receive(:exit)
  end

  describe '#breadcrumbs_trail' do
    subject { helper.breadcrumbs_trail }

    context 'legacy identifiers' do
      context 'root' do
        before do
          ctx.create_item('root', {}, Nanoc::Identifier.new('/', type: :legacy))

          ctx.item = ctx.items['/']
        end

        it 'returns an array with the item' do
          expect(subject).to eql([ctx.items['/']])
        end
      end

      context 'root and direct child' do
        before do
          ctx.create_item('child', {}, Nanoc::Identifier.new('/foo/', type: :legacy))
          ctx.create_item('root', {}, Nanoc::Identifier.new('/', type: :legacy))

          ctx.item = ctx.items['/foo/']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/'], ctx.items['/foo/']])
        end
      end

      context 'root, child and grandchild' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Identifier.new('/foo/bar/', type: :legacy))
          ctx.create_item('child', {}, Nanoc::Identifier.new('/foo/', type: :legacy))
          ctx.create_item('root', {}, Nanoc::Identifier.new('/', type: :legacy))

          ctx.item = ctx.items['/foo/bar/']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/'], ctx.items['/foo/'], ctx.items['/foo/bar/']])
        end
      end

      context 'root, missing child and grandchild' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Identifier.new('/foo/bar/', type: :legacy))
          ctx.create_item('root', {}, Nanoc::Identifier.new('/', type: :legacy))

          ctx.item = ctx.items['/foo/bar/']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/'], nil, ctx.items['/foo/bar/']])
        end
      end
    end

    context 'non-legacy identifiers' do
      context 'root' do
        before do
          ctx.create_item('root', {}, Nanoc::Identifier.new('/index.md'))

          ctx.item = ctx.items['/index.md']
        end

        it 'returns an array with the item' do
          expect(subject).to eql([ctx.items['/index.md']])
        end
      end

      context 'root and direct child' do
        before do
          ctx.create_item('child', {}, Nanoc::Identifier.new('/foo.md'))
          ctx.create_item('root', {}, Nanoc::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo.md']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/index.md'], ctx.items['/foo.md']])
        end
      end

      context 'root, child and grandchild' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Identifier.new('/foo/bar.md'))
          ctx.create_item('child', {}, Nanoc::Identifier.new('/foo.md'))
          ctx.create_item('root', {}, Nanoc::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo/bar.md']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/index.md'], ctx.items['/foo.md'], ctx.items['/foo/bar.md']])
        end
      end

      context 'root, missing child and grandchild' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Identifier.new('/foo/bar.md'))
          ctx.create_item('root', {}, Nanoc::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo/bar.md']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/index.md'], nil, ctx.items['/foo/bar.md']])
        end
      end

      context 'index.md child' do
        # No special handling of non-root index.* files.

        before do
          ctx.create_item('grandchild', {}, Nanoc::Identifier.new('/foo/index.md'))
          ctx.create_item('root', {}, Nanoc::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo/index.md']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/index.md'], nil, ctx.items['/foo/index.md']])
        end
      end

      context 'item with version number component in path' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Identifier.new('/1.5/stuff.md'))
          ctx.create_item('child0', {}, Nanoc::Identifier.new('/1.4.md'))
          ctx.create_item('child1', {}, Nanoc::Identifier.new('/1.5.md'))
          ctx.create_item('child2', {}, Nanoc::Identifier.new('/1.6.md'))
          ctx.create_item('root', {}, Nanoc::Identifier.new('/index.md'))

          ctx.item = ctx.items['/1.5/stuff.md']
        end

        it 'picks the closest parent' do
          expect(subject)
            .to eql(
              [
                ctx.items['/index.md'],
                ctx.items['/1.5.md'],
                ctx.items['/1.5/stuff.md'],
              ],
            )
        end
      end

      context 'item with multiple extensions in path' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Identifier.new('/foo/stuff.md'))
          ctx.create_item('child0', {}, Nanoc::Identifier.new('/foo.md.erb'))
          ctx.create_item('child1', {}, Nanoc::Identifier.new('/foo.md'))
          ctx.create_item('child2', {}, Nanoc::Identifier.new('/foo.erb'))
          ctx.create_item('root', {}, Nanoc::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo/stuff.md']
        end

        it 'picks the closest parent' do
          expect(subject)
            .to eql(
              [
                ctx.items['/index.md'],
                ctx.items['/foo.md.erb'],
                ctx.items['/foo/stuff.md'],
              ],
            )
        end
      end
    end
  end
end
