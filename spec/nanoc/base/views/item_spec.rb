# encoding: utf-8

describe Nanoc::ItemView do
  describe '#==' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item) }

    subject { view == other }

    context 'comparing with item with same identifier' do
      let(:other) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
      it { should equal(true) }
    end

    context 'comparing with item with different identifier' do
      let(:other) { Nanoc::Int::Item.new('content', {}, '/fdsa/') }
      it { should equal(false) }
    end

    context 'comparing with item view with same identifier' do
      let(:other) { Nanoc::ItemView.new(Nanoc::Int::Item.new('content', {}, '/asdf/')) }
      it { should equal(true) }
    end

    context 'comparing with item view with different identifier' do
      let(:other) { Nanoc::ItemView.new(Nanoc::Int::Item.new('content', {}, '/fdsa/')) }
      it { should equal(false) }
    end
  end

  describe '#hash' do
    let(:item) { double(:item, identifier: '/foo/') }
    let(:view) { described_class.new(item) }

    subject { view.hash }

    it { should == described_class.hash ^ '/foo/'.hash }
  end
end
