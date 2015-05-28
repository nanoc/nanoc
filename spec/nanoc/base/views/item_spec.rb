# encoding: utf-8

describe Nanoc::ItemView do
  describe '#== and #eql?' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item) }

    context 'comparing with item with same identifier' do
      let(:other) { Nanoc::Int::Item.new('content', {}, '/asdf/') }

      it 'is equal' do
        expect(view).to eq(other)
        expect(view).to eql(other)
      end
    end

    context 'comparing with item with different identifier' do
      let(:other) { Nanoc::Int::Item.new('content', {}, '/fdsa/') }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item view with same identifier' do
      let(:other) { Nanoc::ItemView.new(Nanoc::Int::Item.new('content', {}, '/asdf/')) }

      it 'is equal' do
        expect(view).to eq(other)
        expect(view).to eql(other)
      end
    end

    context 'comparing with item view with different identifier' do
      let(:other) { Nanoc::ItemView.new(Nanoc::Int::Item.new('content', {}, '/fdsa/')) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end
  end

  describe '#raw_content' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item) }

    subject { view.raw_content }

    it { should eq('content') }
  end

  describe '#hash' do
    let(:item) { double(:item, identifier: '/foo/') }
    let(:view) { described_class.new(item) }

    subject { view.hash }

    it { should == described_class.hash ^ '/foo/'.hash }
  end

  describe '#parent' do
    let(:item) do
      Nanoc::Int::Item.new('me', {}, '/me/').tap { |i| i.parent = parent_item }
    end

    let(:view) { described_class.new(item) }

    subject { view.parent }

    context 'with parent' do
      let(:parent_item) do
        Nanoc::Int::Item.new('parent', {}, '/parent/')
      end

      it 'returns a view for the parent' do
        expect(subject.class).to eql(Nanoc::ItemView)
        expect(subject.unwrap).to eql(parent_item)
      end
    end

    context 'without parent' do
      let(:parent_item) do
        nil
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#[]' do
    let(:item) { Nanoc::Int::Item.new('stuff', { animal: 'donkey' }, '/foo/') }
    let(:view) { described_class.new(item) }

    subject { view[key] }

    context 'with existant key' do
      let(:key) { :animal }
      it { should eql?('donkey') }
    end

    context 'with non-existant key' do
      let(:key) { :weapon }
      it { should eql?(nil) }
    end
  end

  describe '#fetch' do
    let(:item) { Nanoc::Int::Item.new('stuff', { animal: 'donkey' }, '/foo/') }
    let(:view) { described_class.new(item) }

    before do
      expect(Nanoc::Int::NotificationCenter).to receive(:post).twice
    end

    context 'with existant key' do
      let(:key) { :animal }

      subject { view.fetch(key) }

      it { should eql?('donkey') }
    end

    context 'with non-existant key' do
      let(:key) { :weapon }

      context 'with fallback' do
        subject { view.fetch(key, 'nothing sorry') }
        it { should eql?('nothing sorry') }
      end

      context 'with block' do
        subject { view.fetch(key) { 'nothing sorry' } }
        it { should eql?('nothing sorry') }
      end

      context 'with no fallback and no block' do
        subject { view.fetch(key) }

        it 'raises' do
          expect { subject }.to raise_error(KeyError)
        end
      end
    end
  end

  describe '#key?' do
    let(:item) { Nanoc::Int::Item.new('stuff', { animal: 'donkey' }, '/foo/') }
    let(:view) { described_class.new(item) }

    before do
      expect(Nanoc::Int::NotificationCenter).to receive(:post).twice
    end

    subject { view.key?(key) }

    context 'with existant key' do
      let(:key) { :animal }
      it { should eql?(true) }
    end

    context 'with non-existant key' do
      let(:key) { :weapon }
      it { should eql?(false) }
    end
  end
end
