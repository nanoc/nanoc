# encoding: utf-8

describe Nanoc::LayoutView do
  describe '#==' do
    let(:layout) { Nanoc::Int::Layout.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(layout) }

    subject { view == other }

    context 'comparing with layout with same identifier' do
      let(:other) { Nanoc::Int::Layout.new('content', {}, '/asdf/') }
      it { should equal(true) }
    end

    context 'comparing with layout with different identifier' do
      let(:other) { Nanoc::Int::Layout.new('content', {}, '/fdsa/') }
      it { should equal(false) }
    end

    context 'comparing with layout view with same identifier' do
      let(:other) { Nanoc::LayoutView.new(Nanoc::Int::Layout.new('content', {}, '/asdf/')) }
      it { should equal(true) }
    end

    context 'comparing with layout view with different identifier' do
      let(:other) { Nanoc::LayoutView.new(Nanoc::Int::Layout.new('content', {}, '/fdsa/')) }
      it { should equal(false) }
    end
  end

  describe '#hash' do
    let(:layout) { double(:layout, identifier: '/foo/') }
    let(:view) { described_class.new(layout) }

    subject { view.hash }

    it { should == described_class.hash ^ '/foo/'.hash }
  end
end
