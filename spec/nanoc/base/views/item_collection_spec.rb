# encoding: utf-8

describe Nanoc::ItemCollectionView do
  let(:wrapped) { double(:wrapped) }
  let(:view) { described_class.new(wrapped) }

  describe '#unwrap' do
    subject { view.unwrap }
    it { should equal(wrapped) }
  end

  describe '#each' do
    let(:wrapped) do
      [
        Nanoc::Int::Item.new('foo', {}, '/foo/'),
        Nanoc::Int::Item.new('bar', {}, '/bar/'),
        Nanoc::Int::Item.new('baz', {}, '/baz/'),
      ]
    end

    it 'returns self' do
      expect(view.each { |i| }).to equal(view)
    end
  end

  describe '#size' do
    let(:wrapped) do
      [
        Nanoc::Int::Item.new('foo', {}, '/foo/'),
        Nanoc::Int::Item.new('bar', {}, '/bar/'),
        Nanoc::Int::Item.new('baz', {}, '/baz/'),
      ]
    end

    subject { view.size }

    it { should == 3 }
  end

  describe '#at' do
    subject { view.at(arg) }

    let(:arg) { 'some argument' }

    context 'wrapped returns item' do
      let(:item) { double(:item) }

      before do
        expect(wrapped).to receive(:at).with(arg) { item }
      end

      it 'returns a wrapped item' do
        expect(subject.class).to equal(Nanoc::ItemView)
        expect(subject.unwrap).to equal(item)
      end
    end

    context 'wrapped returns nil' do
      before do
        expect(wrapped).to receive(:at).with(arg) { nil }
      end

      it { should equal(nil) }
    end
  end

  describe '#[]' do
    subject { view[arg] }

    let(:arg) { 'some argument' }

    context 'wrapped returns nil' do
      before do
        expect(wrapped).to receive(:[]).with(arg) { nil }
      end

      it { should equal(nil) }
    end

    context 'wrapped returns item' do
      let(:item) { double(:item) }

      before do
        expect(wrapped).to receive(:[]).with(arg) { item }
      end

      it 'returns wrapped item' do
        expect(subject.class).to equal(Nanoc::ItemView)
        expect(subject.unwrap).to equal(item)
      end
    end
  end

  describe '#find_all' do
    let(:wrapped) do
      [
        Nanoc::Int::Item.new('foo', {}, Nanoc::Identifier.new('/about.css', style: :full)),
        Nanoc::Int::Item.new('bar', {}, Nanoc::Identifier.new('/about.md', style: :full)),
        Nanoc::Int::Item.new('baz', {}, Nanoc::Identifier.new('/style.css', style: :full)),
      ]
    end

    subject { view.find_all(arg) }

    context 'with string' do
      let(:arg) { '/*.css' }

      it 'contains item views' do
        expect(subject.size).to eql(2)
        about_css = subject.find { |iv| iv.identifier == '/about.css' }
        style_css = subject.find { |iv| iv.identifier == '/style.css' }
        expect(about_css.class).to equal(Nanoc::ItemView)
        expect(style_css.class).to equal(Nanoc::ItemView)
      end
    end

    context 'with regex' do
      let(:arg) { %r{\.css\z} }

      it 'contains item views' do
        expect(subject.size).to eql(2)
        about_css = subject.find { |iv| iv.identifier == '/about.css' }
        style_css = subject.find { |iv| iv.identifier == '/style.css' }
        expect(about_css.class).to equal(Nanoc::ItemView)
        expect(style_css.class).to equal(Nanoc::ItemView)
      end
    end
  end
end
