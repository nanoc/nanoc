# frozen_string_literal: true

describe Nanoc::Filters::RelativizePaths do
  subject(:filter) { described_class.new(assigns) }

  let(:assigns) do
    { item_rep: item_rep }
  end

  let(:item) do
    Nanoc::Int::Item.new('contentz', {}, '/sub/page.html')
  end

  let(:item_rep) do
    Nanoc::Int::ItemRep.new(item, :default).tap do |rep|
      rep.paths = { last: ['/sub/page.html'] }
    end
  end

  describe '#run' do
    subject { filter.setup_and_run(content, params) }

    let(:content) do
      '<a href="/foo">Foo</a>'
    end

    let(:params) do
      {}
    end

    context 'HTML' do
      let(:params) { { type: :html } }
      it { is_expected.to eq('<a href="../foo">Foo</a>') }
    end

    context 'HTML5' do
      let(:params) { { type: :html5 } }
      it { is_expected.to eq('<a href="../foo">Foo</a>') }
    end

    context 'XHTML' do
      let(:params) { { type: :xhtml } }
      it { is_expected.to eq('<a href="../foo">Foo</a>') }
    end

    context 'CSS' do
      let(:params) { { type: :css } }
      let(:content) do
        '.oink { background: url(/foo.png) }'
      end

      it { is_expected.to eq('.oink { background: url(../foo.png) }') }
    end
  end
end
