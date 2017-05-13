# frozen_string_literal: true

describe Nanoc::Helpers::LinkTo, helper: true do
  describe '#link_to' do
    subject { helper.link_to(text, target, attributes) }

    let(:text) { 'Text' }
    let(:target) { raise 'override me' }
    let(:attributes) { {} }

    context 'with string path' do
      let(:target) { '/foo/' }
      it { is_expected.to eql('<a href="/foo/">Text</a>') }

      context 'with attributes' do
        let(:attributes) { { title: 'Donkey' } }
        it { is_expected.to eql('<a title="Donkey" href="/foo/">Text</a>') }
      end

      context 'special HTML characters in text' do
        let(:text) { 'Foo &amp; Bar' }
        it { is_expected.to eql('<a href="/foo/">Foo &amp; Bar</a>') }
        # Not escaped!
      end

      context 'special HTML characters in URL' do
        let(:target) { '/r&d/' }
        it { is_expected.to eql('<a href="/r&amp;d/">Text</a>') }
      end

      context 'special HTML characters in attribute' do
        let(:attributes) { { title: 'Research & Development' } }
        it { is_expected.to eql('<a title="Research &amp; Development" href="/foo/">Text</a>') }
      end
    end

    context 'with rep' do
      before do
        ctx.create_item('content', {}, '/target/')
        ctx.create_rep(ctx.items['/target/'], '/target.html')
      end

      let(:target) { ctx.items['/target/'].reps[:default] }

      it { is_expected.to eql('<a href="/target.html">Text</a>') }
    end

    context 'with item' do
      before do
        ctx.create_item('content', {}, '/target/')
      end

      let(:target) { ctx.items['/target/'] }

      before do
        ctx.create_rep(target, '/target.html')
      end

      it { is_expected.to eql('<a href="/target.html">Text</a>') }
    end

    context 'with nil' do
      let(:target) { nil }

      it 'raises' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'with something else' do
      let(:target) { :donkey }

      it 'raises' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'with nil path' do
      before do
        ctx.create_item('content', {}, '/target/')
        ctx.create_rep(ctx.items['/target/'], nil)
      end

      let(:target) { ctx.items['/target/'].reps[:default] }

      it 'raises' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#link_to_unless_current' do
    subject { helper.link_to_unless_current(text, target, attributes) }

    let(:text) { 'Text' }
    let(:target) { raise 'override me' }
    let(:attributes) { {} }

    context 'with string path' do
      let(:target) { '/target.html' }

      context 'current' do
        before do
          ctx.create_item('content', {}, '/target.md')
          ctx.create_rep(ctx.items['/target.md'], '/target.html')

          ctx.item = ctx.items['/target.md']
          ctx.item_rep = ctx.item.reps[:default]
        end

        it { is_expected.to eql('<span class="active">Text</span>') }
      end

      context 'no item rep present' do
        it { is_expected.to eql('<a href="/target.html">Text</a>') }
      end

      context 'item rep present, but not current' do
        before do
          ctx.create_item('content', {}, '/other.md')
          ctx.create_rep(ctx.items['/other.md'], '/other.html')

          ctx.item = ctx.items['/other.md']
          ctx.item_rep = ctx.item.reps[:default]
        end

        it { is_expected.to eql('<a href="/target.html">Text</a>') }
      end
    end

    context 'with rep' do
      before do
        ctx.create_item('content', {}, '/target.md')
        ctx.create_rep(ctx.items['/target.md'], '/target.html')

        ctx.create_item('content', {}, '/other.md')
        ctx.create_rep(ctx.items['/other.md'], '/other.html')

        ctx.item = ctx.items['/target.md']
        ctx.item_rep = ctx.item.reps[:default]
      end

      let(:some_item) { ctx.items['/other.md'] }
      let(:some_item_rep) { some_item.reps[:default] }

      context 'current' do
        let(:target) { ctx.item_rep }
        it { is_expected.to eql('<span class="active">Text</span>') }
      end

      context 'no item rep present' do
        let(:target) { some_item_rep }

        before do
          ctx.item = nil
          ctx.item_rep = nil
        end

        it { is_expected.to eql('<a href="/other.html">Text</a>') }
      end

      context 'item rep present, but not current' do
        let(:target) { some_item_rep }
        it { is_expected.to eql('<a href="/other.html">Text</a>') }
      end
    end

    context 'with item' do
      before do
        ctx.create_item('content', {}, '/target.md')
        ctx.create_rep(ctx.items['/target.md'], '/target.html')

        ctx.create_item('content', {}, '/other.md')
        ctx.create_rep(ctx.items['/other.md'], '/other.html')

        ctx.item = ctx.items['/target.md']
        ctx.item_rep = ctx.item.reps[:default]
      end

      let(:some_item) { ctx.items['/other.md'] }
      let(:some_item_rep) { some_item.reps[:default] }

      context 'current' do
        let(:target) { ctx.item }
        it { is_expected.to eql('<span class="active">Text</span>') }
      end

      context 'no item rep present' do
        let(:target) { some_item }

        before do
          ctx.item = nil
          ctx.item_rep = nil
        end

        it { is_expected.to eql('<a href="/other.html">Text</a>') }
      end

      context 'item rep present, but not current' do
        let(:target) { some_item }
        it { is_expected.to eql('<a href="/other.html">Text</a>') }
      end
    end
  end

  describe '#relative_path_to' do
    subject { helper.relative_path_to(target) }

    before do
      ctx.create_item('content', {}, '/foo/self.md')
      ctx.create_rep(ctx.items['/foo/self.md'], self_path)

      ctx.item = ctx.items['/foo/self.md']
      ctx.item_rep = ctx.item.reps[:default]
    end

    context 'current item rep has non-nil path' do
      let(:self_path) { '/foo/self.html' }

      context 'to string path' do
        context 'to relative path' do
          let(:target) { 'bar/target.html' }

          it 'errors' do
            # TODO: Might make sense to allow this case (and return the path itself)
            expect { subject }.to raise_error(ArgumentError)
          end
        end

        context 'to path without trailing slash' do
          let(:target) { '/bar/target.html' }
          it { is_expected.to eql('../bar/target.html') }
        end

        context 'to path with trailing slash' do
          let(:target) { '/bar/target/' }
          it { is_expected.to eql('../bar/target/') }
        end

        context 'to Windows/UNC path (forward slashes)' do
          let(:target) { '//foo' }
          it { is_expected.to eql('//foo') }
        end

        context 'to Windows/UNC path (backslashes)' do
          let(:target) { '\\\\foo' }
          it { is_expected.to eql('\\\\foo') }
        end
      end

      context 'to rep' do
        before do
          ctx.create_rep(ctx.item, '/bar/target.html', :special)
        end

        let(:target) { ctx.item.reps[:special] }

        it { is_expected.to eql('../bar/target.html') }

        context 'to self' do
          let(:target) { ctx.item_rep }

          context 'self is a filename' do
            it { is_expected.to eql('self.html') }
          end

          context 'self is a directory' do
            let(:self_path) { '/foo/self/' }
            it { is_expected.to eql('./') }
          end
        end
      end

      context 'to item' do
        let(:target) { ctx.items['/bar/target.md'] }

        before do
          ctx.create_item('content', {}, '/bar/target.md')
          ctx.create_rep(ctx.items['/bar/target.md'], '/bar/target.html')
        end

        it { is_expected.to eql('../bar/target.html') }

        context 'to self' do
          let(:target) { ctx.item }

          context 'self is a filename' do
            it { is_expected.to eql('self.html') }
          end

          context 'self is a directory' do
            let(:self_path) { '/foo/self/' }
            it { is_expected.to eql('./') }
          end
        end
      end

      context 'to nil path' do
        let(:target) { ctx.item.reps[:special] }

        before do
          ctx.create_rep(ctx.item, nil, :special)
        end

        it 'raises' do
          expect { subject }.to raise_error(RuntimeError)
        end
      end
    end

    context 'current item rep has nil path' do
      let(:self_path) { nil }
      let(:target) { '/bar/target.html' }

      it 'errors' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end
end
