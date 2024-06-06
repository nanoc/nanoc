# frozen_string_literal: true

describe Nanoc::Filters::RelativizePaths do
  subject(:filter) { described_class.new(assigns) }

  let(:assigns) do
    { item_rep: }
  end

  let(:item) do
    Nanoc::Core::Item.new('contentz', {}, '/sub/page.html')
  end

  let(:item_rep) do
    Nanoc::Core::ItemRep.new(item, :default).tap do |rep|
      rep.paths = { last: ['/sub/page.html'] }
    end
  end

  describe '#run' do
    subject { filter.setup_and_run(content, params) }

    let(:content) do
      '<a href="/foo/bar">Foo</a>'
    end

    let(:params) do
      {}
    end

    context 'HTML' do
      let(:params) { { type: :html } }

      it { is_expected.to eq('<a href="../foo/bar">Foo</a>') }

      context 'full component excluded' do
        let(:params) { { type: :html, exclude: '/foo' } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end

      context 'full component excluded as list' do
        let(:params) { { type: :html, exclude: ['/foo'] } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end

      context 'partial component excluded' do
        let(:params) { { type: :html, exclude: ['/fo'] } }

        it { is_expected.to eq('<a href="../foo/bar">Foo</a>') }
      end

      context 'non-root component excluded' do
        let(:params) { { type: :html, exclude: ['/bar'] } }

        it { is_expected.to eq('<a href="../foo/bar">Foo</a>') }
      end

      context 'excluded with regexp' do
        let(:params) { { type: :html, exclude: /ar/ } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end

      context 'excluded with regexp list' do
        let(:params) { { type: :html, exclude: [/ar/] } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end
    end

    context 'HTML5' do
      let(:params) { { type: :html5 } }

      it { is_expected.to eq('<a href="../foo/bar">Foo</a>') }

      context 'full component excluded' do
        let(:params) { { type: :html5, exclude: '/foo' } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end

      context 'full component excluded as list' do
        let(:params) { { type: :html5, exclude: ['/foo'] } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end

      context 'partial component excluded' do
        let(:params) { { type: :html5, exclude: ['/fo'] } }

        it { is_expected.to eq('<a href="../foo/bar">Foo</a>') }
      end

      context 'non-root component excluded' do
        let(:params) { { type: :html5, exclude: ['/bar'] } }

        it { is_expected.to eq('<a href="../foo/bar">Foo</a>') }
      end

      context 'excluded with regexp' do
        let(:params) { { type: :html5, exclude: /ar/ } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end

      context 'excluded with regexp list' do
        let(:params) { { type: :html5, exclude: [/ar/] } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end

      context 'img src' do
        let(:content) { '<img src="/foo/bar.png">' }

        it { is_expected.to eq('<img src="../foo/bar.png">') }
      end

      context 'form action' do
        let(:content) { '<form action="/foo/bar"><button>Submit</button></form>' }

        it { is_expected.to eq('<form action="../foo/bar"><button>Submit</button></form>') }
      end

      context 'object data' do
        let(:content) { '<object data="/foo/bar"></object>' }

        it { is_expected.to eq('<object data="../foo/bar"></object>') }
      end

      context 'param value' do
        let(:content) { '<param name="movie" value="/foo/bar.swf">' }

        it { is_expected.to eq('<param name="movie" value="../foo/bar.swf">') }
      end

      context 'img srcset' do
        let(:content) { '<img srcset="  /foo/bar.png 1w 2x , /foo/bloop.png 2w, /foo/asdf.jpg 12w 128x ">' }

        it { is_expected.to eq('<img srcset="../foo/bar.png 1w 2x,../foo/bloop.png 2w,../foo/asdf.jpg 12w 128x">') }
      end

      context 'video' do
        let(:content) { '<video poster="/foo.png"><source src="/foo.mp4" type="video/mp4"></video>' }

        it { is_expected.to eq('<video poster="../foo.png"><source src="../foo.mp4" type="video/mp4"></video>') }
      end
    end

    context 'XHTML' do
      let(:params) { { type: :xhtml } }

      it { is_expected.to eq('<a href="../foo/bar">Foo</a>') }

      context 'full component excluded' do
        let(:params) { { type: :xhtml, exclude: '/foo' } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end

      context 'full component excluded as list' do
        let(:params) { { type: :xhtml, exclude: ['/foo'] } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end

      context 'partial component excluded' do
        let(:params) { { type: :xhtml, exclude: ['/fo'] } }

        it { is_expected.to eq('<a href="../foo/bar">Foo</a>') }
      end

      context 'non-root component excluded' do
        let(:params) { { type: :xhtml, exclude: ['/bar'] } }

        it { is_expected.to eq('<a href="../foo/bar">Foo</a>') }
      end

      context 'excluded with regexp' do
        let(:params) { { type: :xhtml, exclude: /ar/ } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end

      context 'excluded with regexp list' do
        let(:params) { { type: :xhtml, exclude: [/ar/] } }

        it { is_expected.to eq('<a href="/foo/bar">Foo</a>') }
      end
    end

    context 'CSS' do
      let(:params) { { type: :css } }

      let(:content) do
        '.oink { background: url(/foo/bar.png) }'
      end

      it { is_expected.to eq('.oink { background: url(../foo/bar.png) }') }

      context 'full component excluded' do
        let(:params) { { type: :css, exclude: '/foo' } }

        it { is_expected.to eq('.oink { background: url(/foo/bar.png) }') }
      end

      context 'full component excluded as list' do
        let(:params) { { type: :css, exclude: ['/foo'] } }

        it { is_expected.to eq('.oink { background: url(/foo/bar.png) }') }
      end

      context 'partial component excluded' do
        let(:params) { { type: :css, exclude: ['/fo'] } }

        it { is_expected.to eq('.oink { background: url(../foo/bar.png) }') }
      end

      context 'non-root component excluded' do
        let(:params) { { type: :css, exclude: ['/bar'] } }

        it { is_expected.to eq('.oink { background: url(../foo/bar.png) }') }
      end

      context 'excluded with regexp' do
        let(:params) { { type: :css, exclude: /ar/ } }

        it { is_expected.to eq('.oink { background: url(/foo/bar.png) }') }
      end

      context 'excluded with regexp list' do
        let(:params) { { type: :css, exclude: [/ar/] } }

        it { is_expected.to eq('.oink { background: url(/foo/bar.png) }') }
      end
    end
  end
end
