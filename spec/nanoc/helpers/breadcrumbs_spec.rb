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
      before do
        ctx.create_item('root', {}, '/index.md')

        ctx.item = ctx.items['/index.md']
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Helpers::Breadcrumbs::CannotGetBreadcrumbsForNonLegacyItem)
      end
    end
  end
end
