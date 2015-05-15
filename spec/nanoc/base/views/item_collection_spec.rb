# encoding: utf-8

describe Nanoc::ItemCollectionView do
  let(:view) { described_class.new(wrapped) }

  let(:config) do
    { pattern_syntax: 'glob' }
  end

  describe '#unwrap' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |arr|
        arr << Nanoc::Int::Item.new('foo', {}, '/foo/')
        arr << Nanoc::Int::Item.new('bar', {}, '/bar/')
        arr << Nanoc::Int::Item.new('baz', {}, '/baz/')
      end
    end

    subject { view.unwrap }

    it { should equal(wrapped) }
  end

  describe '#each' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |arr|
        arr << Nanoc::Int::Item.new('foo', {}, '/foo/')
        arr << Nanoc::Int::Item.new('bar', {}, '/bar/')
        arr << Nanoc::Int::Item.new('baz', {}, '/baz/')
      end
    end

    it 'returns self' do
      expect(view.each { |i| }).to equal(view)
    end
  end

  describe '#size' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |arr|
        arr << Nanoc::Int::Item.new('foo', {}, '/foo/')
        arr << Nanoc::Int::Item.new('bar', {}, '/bar/')
        arr << Nanoc::Int::Item.new('baz', {}, '/baz/')
      end
    end

    subject { view.size }

    it { should == 3 }
  end

  describe '#[]' do
    let(:page_item) { Nanoc::Int::Item.new('foo', {}, Nanoc::Identifier.new('/page.erb', style: :full)) }
    let(:home_item) { Nanoc::Int::Item.new('bar', {}, Nanoc::Identifier.new('/home.erb', style: :full)) }

    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |arr|
        arr << page_item
        arr << home_item
      end
    end

    subject { view[arg] }

    context 'no items found' do
      let(:arg) { '/donkey.*' }
      it { is_expected.to equal(nil) }
    end

    context 'direct identifier' do
      let(:arg) { '/home.erb' }

      it 'returns wrapped item' do
        expect(subject.class).to equal(Nanoc::ItemView)
        expect(subject.unwrap).to equal(home_item)
      end
    end

    context 'glob' do
      let(:arg) { '/home.*' }

      context 'globs not enabled' do
        let(:config) { { pattern_syntax: nil } }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'globs enabled' do
        it 'returns wrapped item' do
          expect(subject.class).to equal(Nanoc::ItemView)
          expect(subject.unwrap).to equal(home_item)
        end
      end
    end

    context 'regex' do
      let(:arg) { %r{\A/home} }

      it 'returns wrapped item' do
        expect(subject.class).to equal(Nanoc::ItemView)
        expect(subject.unwrap).to equal(home_item)
      end
    end
  end

  describe '#find_all' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |arr|
        arr << Nanoc::Int::Item.new('foo', {}, Nanoc::Identifier.new('/about.css', style: :full))
        arr << Nanoc::Int::Item.new('bar', {}, Nanoc::Identifier.new('/about.md', style: :full))
        arr << Nanoc::Int::Item.new('baz', {}, Nanoc::Identifier.new('/style.css', style: :full))
      end
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
