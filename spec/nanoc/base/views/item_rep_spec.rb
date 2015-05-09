# encoding: utf-8

describe Nanoc::ItemRepView do
  describe '#==' do
    let(:item_rep) { double(:item_rep, item: item, name: :jacques) }
    let(:item) { double(:item, identifier: '/foo/') }
    let(:view) { described_class.new(item_rep) }

    subject { view == other }

    context 'comparing with item rep with same identifier' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { double(:other_item_rep, item: other_item, name: :jacques) }
      it { should equal(true) }
    end

    context 'comparing with item rep with different identifier' do
      let(:other_item) { double(:other_item, identifier: '/bar/') }
      let(:other) { double(:other_item_rep, item: other_item, name: :jacques) }
      it { should equal(false) }
    end

    context 'comparing with item rep with different name' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { double(:other_item_rep, item: other_item, name: :marvin) }
      it { should equal(false) }
    end

    context 'comparing with item rep with same identifier' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :jacques)) }
      it { should equal(true) }
    end

    context 'comparing with item rep with different identifier' do
      let(:other_item) { double(:other_item, identifier: '/bar/') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :jacques)) }
      it { should equal(false) }
    end

    context 'comparing with item rep with different name' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :marvin)) }
      it { should equal(false) }
    end
  end

  describe '#hash' do
    let(:item_rep) { double(:item_rep, item: item, name: :jacques) }
    let(:item) { double(:item, identifier: '/foo/') }
    let(:view) { described_class.new(item_rep) }

    subject { view.hash }

    it { should == described_class.hash ^ '/foo/'.hash ^ :jacques.hash }
  end
end
