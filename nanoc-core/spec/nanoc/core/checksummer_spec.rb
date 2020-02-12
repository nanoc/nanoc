# frozen_string_literal: true

describe Nanoc::Core::Checksummer::VerboseDigest do
  let(:digest) { described_class.new }

  it 'concatenates' do
    digest.update('foo')
    digest.update('bar')
    expect(digest.to_s).to eql('foobar')
  end
end

describe Nanoc::Core::Checksummer::CompactDigest do
  let(:digest) { described_class.new }

  it 'uses SHA1 and Base64' do
    digest.update('foo')
    digest.update('bar')
    expect(digest.to_s).to eql(Digest::SHA1.base64digest('foobar'))
  end
end

describe Nanoc::Core::Checksummer do
  subject { described_class.calc(obj, Nanoc::Core::Checksummer::VerboseDigest) }

  describe '.calc_for_each_attribute_of' do
    let(:obj) { Nanoc::Core::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md') }

    context 'compact' do
      subject do
        described_class.calc_for_each_attribute_of(obj)
      end

      it { is_expected.to have_key(:foo) }
    end

    context 'verbose' do
      subject do
        described_class.calc_for_each_attribute_of(obj, Nanoc::Core::Checksummer::VerboseDigest)
      end

      it { is_expected.to eq(foo: 'String<bar>') }
    end
  end

  context 'String' do
    let(:obj) { 'hello' }

    it { is_expected.to eql('String<hello>') }
  end

  context 'Symbol' do
    let(:obj) { :hello }

    it { is_expected.to eql('Symbol<hello>') }
  end

  context 'nil' do
    let(:obj) { nil }

    it { is_expected.to eql('NilClass<>') }
  end

  context 'true' do
    let(:obj) { true }

    it { is_expected.to eql('TrueClass<>') }
  end

  context 'false' do
    let(:obj) { false }

    it { is_expected.to eql('FalseClass<>') }
  end

  context 'Array' do
    let(:obj) { %w[hello goodbye] }

    it { is_expected.to eql('Array<String<hello>,String<goodbye>,>') }

    context 'different order' do
      let(:obj) { %w[goodbye hello] }

      it { is_expected.to eql('Array<String<goodbye>,String<hello>,>') }
    end

    context 'recursive' do
      let(:obj) { [].tap { |arr| arr << ['hello', arr] } }

      it { is_expected.to eql('Array<Array<String<hello>,Array<recur>,>,>') }
    end

    context 'non-serializable' do
      let(:obj) { [-> {}] }

      it { is_expected.to match(/\AArray<Proc<#<Proc:0x.*>>,>\z/) }
    end
  end

  context 'Hash' do
    let(:obj) { { 'a' => 'foo', 'b' => 'bar' } }

    it { is_expected.to eql('Hash<String<a>=String<foo>,String<b>=String<bar>,>') }

    context 'different order' do
      let(:obj) { { 'b' => 'bar', 'a' => 'foo' } }

      it { is_expected.to eql('Hash<String<b>=String<bar>,String<a>=String<foo>,>') }
    end

    context 'non-serializable' do
      let(:obj) { { 'a' => -> {} } }

      it { is_expected.to match(/\AHash<String<a>=Proc<#<Proc:0x.*>>,>\z/) }
    end

    context 'recursive values' do
      let(:obj) { {}.tap { |hash| hash['a'] = hash } }

      it { is_expected.to eql('Hash<String<a>=Hash<recur>,>') }
    end

    context 'recursive keys' do
      let(:obj) { {}.tap { |hash| hash[hash] = 'hello' } }

      it { is_expected.to eql('Hash<Hash<recur>=String<hello>,>') }
    end
  end

  context 'Pathname' do
    let(:obj) { ::Pathname.new(filename) }

    let(:filename) { '/tmp/whatever' }
    let(:mtime) { 200 }
    let(:data) { 'stuffs' }

    before do
      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, data)
      File.utime(mtime, mtime, filename)
    end

    it { is_expected.to eql('Pathname<6-200>') }

    context 'does not exist' do
      before do
        FileUtils.rm_rf(filename)
      end

      it { is_expected.to eql('Pathname<???>') }
    end

    context 'different data' do
      let(:data) { 'other stuffs :o' }

      it { is_expected.to eql('Pathname<15-200>') }
    end
  end

  context 'Time' do
    let(:obj) { Time.at(111_223) }

    it { is_expected.to eql('Time<111223>') }
  end

  context 'Float' do
    let(:obj) { 3.14 }

    it { is_expected.to eql('Float<3.14>') }
  end

  context 'Fixnum/Integer' do
    let(:obj) { 3 }

    it { is_expected.to match(/\A(Integer|Fixnum)<3>\z/) }
  end

  context 'Nanoc::Core::Identifier' do
    let(:obj) { Nanoc::Core::Identifier.new('/foo.md') }

    it { is_expected.to eql('Nanoc::Core::Identifier<String</foo.md>>') }
  end

  context 'Nanoc::Core::Configuration' do
    let(:obj) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }

    it { is_expected.to eql('Nanoc::Core::Configuration<Symbol<foo>=String<bar>,>') }
  end

  context 'Nanoc::Core::Item' do
    let(:obj) { Nanoc::Core::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<Symbol<foo>=String<bar>,>,identifier=Nanoc::Core::Identifier<String</foo.md>>>') }

    context 'binary' do
      let(:filename) { File.expand_path('foo.dat') }
      let(:content) { Nanoc::Core::BinaryContent.new(filename) }
      let(:obj) { Nanoc::Core::Item.new(content, { 'foo' => 'bar' }, '/foo.md') }

      let(:mtime) { 200 }
      let(:data) { 'stuffs' }

      before do
        File.write(content.filename, data)
        File.utime(mtime, mtime, content.filename)
      end

      it { is_expected.to eql('Nanoc::Core::Item<content=Nanoc::Core::BinaryContent<Pathname<6-200>>,attributes=Hash<Symbol<foo>=String<bar>,>,identifier=Nanoc::Core::Identifier<String</foo.md>>>') }
    end

    context 'recursive attributes' do
      before do
        obj.attributes[:foo] = obj
      end

      it { is_expected.to eql('Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<Symbol<foo>=Nanoc::Core::Item<recur>,>,identifier=Nanoc::Core::Identifier<String</foo.md>>>') }
    end

    context 'with checksum' do
      let(:obj) { Nanoc::Core::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md', checksum_data: 'abcdef') }

      it { is_expected.to eql('Nanoc::Core::Item<checksum_data=abcdef>') }
    end

    context 'with content checksum' do
      let(:obj) { Nanoc::Core::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md', content_checksum_data: 'con-cs') }

      it { is_expected.to eql('Nanoc::Core::Item<content_checksum_data=con-cs,attributes=Hash<Symbol<foo>=String<bar>,>,identifier=Nanoc::Core::Identifier<String</foo.md>>>') }
    end

    context 'with attributes checksum' do
      let(:obj) { Nanoc::Core::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md', attributes_checksum_data: 'attr-cs') }

      it { is_expected.to eql('Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes_checksum_data=attr-cs,identifier=Nanoc::Core::Identifier<String</foo.md>>>') }
    end
  end

  context 'Nanoc::Core::Layout' do
    let(:obj) { Nanoc::Core::Layout.new('asdf', { 'foo' => 'bar' }, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::Layout<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<Symbol<foo>=String<bar>,>,identifier=Nanoc::Core::Identifier<String</foo.md>>>') }

    context 'recursive attributes' do
      before do
        obj.attributes[:foo] = obj
      end

      it { is_expected.to eql('Nanoc::Core::Layout<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<Symbol<foo>=Nanoc::Core::Layout<recur>,>,identifier=Nanoc::Core::Identifier<String</foo.md>>>') }
    end

    context 'with checksum' do
      let(:obj) { Nanoc::Core::Layout.new('asdf', { 'foo' => 'bar' }, '/foo.md', checksum_data: 'abcdef') }

      it { is_expected.to eql('Nanoc::Core::Layout<checksum_data=abcdef>') }
    end
  end

  context 'Nanoc::Core::ItemRep' do
    let(:obj) { Nanoc::Core::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::ItemRep<item=Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,name=Symbol<pdf>>') }
  end

  context 'Nanoc::Core::Context' do
    let(:obj) { Nanoc::Core::Context.new(foo: 123) }

    it { is_expected.to match(/\ANanoc::Core::Context<@foo=(Fixnum|Integer)<123>,>\z/) }
  end

  context 'Nanoc::Core::CodeSnippet' do
    let(:obj) { Nanoc::Core::CodeSnippet.new('asdf', '/bob.rb') }

    it { is_expected.to eql('Nanoc::Core::CodeSnippet<String<asdf>>') }
  end

  context 'Nanoc::Core::CompilationItemView' do
    let(:obj) { Nanoc::Core::CompilationItemView.new(item, nil) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::CompilationItemView<Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>>') }
  end

  context 'Nanoc::Core::BasicItemRepView' do
    let(:obj) { Nanoc::Core::BasicItemRepView.new(rep, nil) }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::BasicItemRepView<Nanoc::Core::ItemRep<item=Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,name=Symbol<pdf>>>') }
  end

  context 'Nanoc::Core::CompilationItemRepView' do
    let(:obj) { Nanoc::Core::CompilationItemRepView.new(rep, nil) }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::CompilationItemRepView<Nanoc::Core::ItemRep<item=Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,name=Symbol<pdf>>>') }
  end

  context 'Nanoc::Core::BasicItemView' do
    let(:obj) { Nanoc::Core::BasicItemView.new(item, nil) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::BasicItemView<Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>>') }
  end

  context 'Nanoc::Core::LayoutView' do
    let(:obj) { Nanoc::Core::LayoutView.new(layout, nil) }
    let(:layout) { Nanoc::Core::Layout.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::LayoutView<Nanoc::Core::Layout<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>>') }
  end

  context 'Nanoc::Core::ConfigView' do
    let(:obj) { Nanoc::Core::ConfigView.new(config, nil) }
    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }

    it { is_expected.to eql('Nanoc::Core::ConfigView<Nanoc::Core::Configuration<Symbol<foo>=String<bar>,>>') }
  end

  context 'Nanoc::Core::ItemCollectionWithRepsView' do
    let(:obj) { Nanoc::Core::ItemCollectionWithRepsView.new(wrapped, nil) }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }

    let(:wrapped) do
      Nanoc::Core::ItemCollection.new(
        config,
        [
          Nanoc::Core::Item.new('foo', {}, '/foo.md'),
          Nanoc::Core::Item.new('bar', {}, '/foo.md'),
        ],
      )
    end

    it { is_expected.to eql('Nanoc::Core::ItemCollectionWithRepsView<Nanoc::Core::ItemCollection<Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<foo>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<bar>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,>>') }
  end

  context 'Nanoc::Core::ItemCollectionWithoutRepsView' do
    let(:obj) { Nanoc::Core::ItemCollectionWithoutRepsView.new(wrapped, nil) }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }

    let(:wrapped) do
      Nanoc::Core::ItemCollection.new(
        config,
        [
          Nanoc::Core::Item.new('foo', {}, '/foo.md'),
          Nanoc::Core::Item.new('bar', {}, '/foo.md'),
        ],
      )
    end

    it { is_expected.to eql('Nanoc::Core::ItemCollectionWithoutRepsView<Nanoc::Core::ItemCollection<Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<foo>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<bar>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,>>') }
  end

  context 'other marshal-able classes' do
    let(:obj) { klass.new('hello') }

    let(:klass) do
      Class.new do
        def initialize(arg)
          @arg = arg
        end
      end
    end

    it { is_expected.to match(/\A#<Class:0x[0-9a-f]+><.*>\z/) }
  end

  context 'other non-marshal-able classes' do
    let(:obj) { proc {} }

    it { is_expected.to match(/\AProc<#<Proc:0x.*>>\z/) }
  end
end
