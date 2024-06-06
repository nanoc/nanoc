# frozen_string_literal: true

describe Nanoc::Helpers::Breadcrumbs, helper: true, stdio: true do
  before do
    allow(ctx.dependency_tracker).to receive(:enter)
    allow(ctx.dependency_tracker).to receive(:exit)
  end

  describe '#breadcrumbs_trail' do
    subject { helper.breadcrumbs_trail }

    context 'legacy identifiers' do
      context 'root' do
        before do
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/', type: :legacy))

          ctx.item = ctx.items['/']
        end

        it 'returns an array with the item' do
          expect(subject).to eql([ctx.items['/']])
        end
      end

      context 'root and direct child' do
        before do
          ctx.create_item('child', {}, Nanoc::Core::Identifier.new('/foo/', type: :legacy))
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/', type: :legacy))

          ctx.item = ctx.items['/foo/']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/'], ctx.items['/foo/']])
        end
      end

      context 'root, child and grandchild' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Core::Identifier.new('/foo/bar/', type: :legacy))
          ctx.create_item('child', {}, Nanoc::Core::Identifier.new('/foo/', type: :legacy))
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/', type: :legacy))

          ctx.item = ctx.items['/foo/bar/']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/'], ctx.items['/foo/'], ctx.items['/foo/bar/']])
        end
      end

      context 'root, missing child and grandchild' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Core::Identifier.new('/foo/bar/', type: :legacy))
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/', type: :legacy))

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
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/index.md'))

          ctx.item = ctx.items['/index.md']
        end

        it 'returns an array with the item' do
          expect(subject).to eql([ctx.items['/index.md']])
        end
      end

      context 'root and direct child' do
        before do
          ctx.create_item('child', {}, Nanoc::Core::Identifier.new('/foo.md'))
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo.md']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/index.md'], ctx.items['/foo.md']])
        end
      end

      context 'root, child and grandchild' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Core::Identifier.new('/foo/bar.md'))
          ctx.create_item('child', {}, Nanoc::Core::Identifier.new('/foo.md'))
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo/bar.md']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/index.md'], ctx.items['/foo.md'], ctx.items['/foo/bar.md']])
        end
      end

      context 'root, missing child and grandchild' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Core::Identifier.new('/foo/bar.md'))
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo/bar.md']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/index.md'], nil, ctx.items['/foo/bar.md']])
        end
      end

      context 'index.md child' do
        # No special handling of non-root index.* files.

        before do
          ctx.create_item('grandchild', {}, Nanoc::Core::Identifier.new('/foo/index.md'))
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo/index.md']
        end

        it 'returns an array with the items' do
          expect(subject).to eql([ctx.items['/index.md'], nil, ctx.items['/foo/index.md']])
        end
      end

      context 'item with version number component in path' do
        before do
          ctx.create_item('grandchild', {}, Nanoc::Core::Identifier.new('/1.5/stuff.md'))
          ctx.create_item('child0', {}, Nanoc::Core::Identifier.new('/1.4.md'))
          ctx.create_item('child1', {}, Nanoc::Core::Identifier.new('/1.5.md'))
          ctx.create_item('child2', {}, Nanoc::Core::Identifier.new('/1.6.md'))
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/index.md'))

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
          ctx.create_item('grandchild', {}, Nanoc::Core::Identifier.new('/foo/stuff.md'))
          ctx.create_item('child0', {}, Nanoc::Core::Identifier.new('/foo.md.erb'))
          ctx.create_item('child1', {}, Nanoc::Core::Identifier.new('/foo.md'))
          ctx.create_item('child2', {}, Nanoc::Core::Identifier.new('/foo.erb'))
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo/stuff.md']
        end

        context 'no tiebreaker specified' do
          it 'picks the first' do
            expect(subject)
              .to eql(
                [
                  ctx.items['/index.md'],
                  ctx.items['/foo.erb'],
                  ctx.items['/foo/stuff.md'],
                ],
              )
          end

          it 'logs a warning' do
            expect { subject }.to output(Regexp.new(Regexp.escape('Warning: The breadcrumbs trail (generated by #breadcrumbs_trail) found more than one potential parent item at /foo.* (found /foo.erb, /foo.md, /foo.md.erb). Nanoc will pick the first item as the parent. Consider eliminating the ambiguity by making only one item match /foo.*, or by passing a `:tiebreaker` option to `#breadcrumbs_trail`. (This situation will be an error in the next major version of Nanoc.)'))).to_stderr
          end
        end

        context 'tiebreaker :error specified' do
          subject { helper.breadcrumbs_trail(tiebreaker: :error) }

          it 'errors because of ambiguity' do
            expect { subject }
              .to raise_error(
                Nanoc::Helpers::Breadcrumbs::AmbiguousAncestorError,
                'expected only one item to match /foo.*, but found 3',
              )
          end
        end

        context 'tiebreaker which picks the last' do
          subject { helper.breadcrumbs_trail(tiebreaker:) }

          let(:tiebreaker) do
            ->(items, _pattern) { items.max_by(&:identifier) }
          end

          it 'picks the last' do
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

        context 'tiebreaker without pattern arg which picks the last' do
          subject { helper.breadcrumbs_trail(tiebreaker:) }

          let(:tiebreaker) do
            ->(items) { items.max_by(&:identifier) }
          end

          it 'picks the last' do
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

      context 'child with multiple extensions' do
        before do
          ctx.create_item('grandchild1', {}, Nanoc::Core::Identifier.new('/foo/stuff.zip'))
          ctx.create_item('grandchild2', {}, Nanoc::Core::Identifier.new('/foo/stuff.md'))
          ctx.create_item('grandchild3', {}, Nanoc::Core::Identifier.new('/foo/stuff.png'))
          ctx.create_item('child', {}, Nanoc::Core::Identifier.new('/foo.md'))
          ctx.create_item('root', {}, Nanoc::Core::Identifier.new('/index.md'))

          ctx.item = ctx.items['/foo/stuff.md']
        end

        it 'picks the best parent' do
          expect(subject)
            .to eql(
              [
                ctx.items['/index.md'],
                ctx.items['/foo.md'],
                ctx.items['/foo/stuff.md'],
              ],
            )
        end
      end
    end
  end
end
