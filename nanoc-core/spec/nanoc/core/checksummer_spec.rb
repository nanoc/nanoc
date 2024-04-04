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

      it { is_expected.to eq(foo: 'String#0<bar>') }
    end
  end

  context 'String' do
    let(:obj) { 'hello' }

    it { is_expected.to eql('String#0<hello>') }
  end

  context 'Symbol' do
    let(:obj) { :hello }

    it { is_expected.to eql('Symbol#0<hello>') }
  end

  context 'nil' do
    let(:obj) { nil }

    it { is_expected.to eql('NilClass#0<>') }
  end

  context 'true' do
    let(:obj) { true }

    it { is_expected.to eql('TrueClass#0<>') }
  end

  context 'false' do
    let(:obj) { false }

    it { is_expected.to eql('FalseClass#0<>') }
  end

  context 'Array' do
    let(:obj) { %w[hello goodbye] }

    it { is_expected.to eql('Array#0<String#1<hello>,String#2<goodbye>,>') }

    context 'different order' do
      let(:obj) { %w[goodbye hello] }

      it { is_expected.to eql('Array#0<String#1<goodbye>,String#2<hello>,>') }
    end

    context 'recursive' do
      let(:obj) { [].tap { |arr| arr << ['hello', arr] } }

      it { is_expected.to eql('Array#0<Array#1<String#2<hello>,@0,>,>') }
    end

    context 'non-serializable' do
      let(:obj) { [-> {}] }

      it { is_expected.to match(/\AArray#0<Proc#1<#<Proc:0x.*>>,>\z/) }
    end
  end

  context 'Set' do
    let(:obj) { Set.new(%w[hello goodbye]) }

    it { is_expected.to eql('Set#0<String#1<goodbye>,String#2<hello>,>') }

    context 'different order' do
      let(:obj) { Set.new(%w[goodbye hello]) }

      it { is_expected.to eql('Set#0<String#1<goodbye>,String#2<hello>,>') }
    end

    context 'recursive' do
      let(:obj) { Set.new.tap { |set| set << Set.new.add('hello').add(set) } }

      it { is_expected.to eql('Set#0<Set#1<String#2<hello>,@0,>,>') }
    end

    context 'non-serializable' do
      let(:obj) { Set.new.add(-> {}) }

      it { is_expected.to match(/\ASet#0<Proc#1<#<Proc:0x.*>>,>\z/) }
    end
  end

  context 'Hash' do
    let(:obj) { { 'a' => 'foo', 'b' => 'bar' } }

    it { is_expected.to eql('Hash#0<String#1<a>=String#2<foo>,String#3<b>=String#4<bar>,>') }

    context 'different order' do
      let(:obj) { { 'b' => 'bar', 'a' => 'foo' } }

      it { is_expected.to eql('Hash#0<String#1<b>=String#2<bar>,String#3<a>=String#4<foo>,>') }
    end

    context 'non-serializable' do
      let(:obj) { { 'a' => -> {} } }

      it { is_expected.to match(/\AHash#0<String#1<a>=Proc#2<#<Proc:0x.*>>,>\z/) }
    end

    context 'recursive values' do
      let(:obj) { {}.tap { |hash| hash['a'] = hash } }

      it { is_expected.to eql('Hash#0<String#1<a>=@0,>') }
    end

    context 'recursive keys' do
      let(:obj) { {}.tap { |hash| hash[hash] = 'hello' } }

      it { is_expected.to eql('Hash#0<@0=String#1<hello>,>') }
    end
  end

  context 'Pathname' do
    let(:obj) { Pathname.new(filename) }

    let(:filename) { '/tmp/whatever' }
    let(:mtime) { 200 }
    let(:data) { 'stuffs' }

    before do
      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, data)
      File.utime(mtime, mtime, filename)
    end

    it { is_expected.to eql('Pathname#0<6-200>') }

    context 'does not exist' do
      before do
        FileUtils.rm_rf(filename)
      end

      it { is_expected.to eql('Pathname#0<???>') }
    end

    context 'different data' do
      let(:data) { 'other stuffs :o' }

      it { is_expected.to eql('Pathname#0<15-200>') }
    end
  end

  context 'Time' do
    let(:obj) { Time.at(111_223) }

    it { is_expected.to eql('Time#0<111223>') }
  end

  context 'Float' do
    let(:obj) { 3.14 }

    it { is_expected.to eql('Float#0<3.14>') }
  end

  context 'Fixnum/Integer' do
    let(:obj) { 3 }

    it { is_expected.to match(/\A(Integer|Fixnum)#0<3>\z/) }
  end

  context 'Nanoc::Core::Identifier' do
    let(:obj) { Nanoc::Core::Identifier.new('/foo.md') }

    it { is_expected.to eql('Nanoc::Core::Identifier#0<String#1</foo.md>>') }
  end

  context 'Nanoc::Core::Configuration' do
    let(:obj) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }

    it { is_expected.to eql('Nanoc::Core::Configuration#0<Symbol#1<foo>=String#2<bar>,>') }
  end

  context 'Nanoc::Core::Item' do
    let(:obj) { Nanoc::Core::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::Item#0<content=Nanoc::Core::TextualContent#1<String#2<asdf>>,attributes=Hash#3<Symbol#4<foo>=String#5<bar>,>,identifier=Nanoc::Core::Identifier#6<String#7</foo.md>>>') }

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

      it { is_expected.to eql('Nanoc::Core::Item#0<content=Nanoc::Core::BinaryContent#1<Pathname#2<6-200>>,attributes=Hash#3<Symbol#4<foo>=String#5<bar>,>,identifier=Nanoc::Core::Identifier#6<String#7</foo.md>>>') }
    end

    context 'recursive attributes' do
      before do
        obj.attributes[:foo] = obj
      end

      it { is_expected.to eql('Nanoc::Core::Item#0<content=Nanoc::Core::TextualContent#1<String#2<asdf>>,attributes=Hash#3<Symbol#4<foo>=@0,>,identifier=Nanoc::Core::Identifier#5<String#6</foo.md>>>') }
    end

    context 'with checksum' do
      let(:obj) { Nanoc::Core::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md', checksum_data: 'abcdef') }

      it { is_expected.to eql('Nanoc::Core::Item#0<checksum_data=abcdef>') }
    end

    context 'with content checksum' do
      let(:obj) { Nanoc::Core::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md', content_checksum_data: 'con-cs') }

      it { is_expected.to eql('Nanoc::Core::Item#0<content_checksum_data=con-cs,attributes=Hash#1<Symbol#2<foo>=String#3<bar>,>,identifier=Nanoc::Core::Identifier#4<String#5</foo.md>>>') }
    end

    context 'with attributes checksum' do
      let(:obj) { Nanoc::Core::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md', attributes_checksum_data: 'attr-cs') }

      it { is_expected.to eql('Nanoc::Core::Item#0<content=Nanoc::Core::TextualContent#1<String#2<asdf>>,attributes_checksum_data=attr-cs,identifier=Nanoc::Core::Identifier#3<String#4</foo.md>>>') }
    end
  end

  context 'Nanoc::Core::Layout' do
    let(:obj) { Nanoc::Core::Layout.new('asdf', { 'foo' => 'bar' }, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::Layout#0<content=Nanoc::Core::TextualContent#1<String#2<asdf>>,attributes=Hash#3<Symbol#4<foo>=String#5<bar>,>,identifier=Nanoc::Core::Identifier#6<String#7</foo.md>>>') }

    context 'recursive attributes' do
      before do
        obj.attributes[:foo] = obj
      end

      it { is_expected.to eql('Nanoc::Core::Layout#0<content=Nanoc::Core::TextualContent#1<String#2<asdf>>,attributes=Hash#3<Symbol#4<foo>=@0,>,identifier=Nanoc::Core::Identifier#5<String#6</foo.md>>>') }
    end

    context 'with checksum' do
      let(:obj) { Nanoc::Core::Layout.new('asdf', { 'foo' => 'bar' }, '/foo.md', checksum_data: 'abcdef') }

      it { is_expected.to eql('Nanoc::Core::Layout#0<checksum_data=abcdef>') }
    end
  end

  context 'Nanoc::Core::ItemRep' do
    let(:obj) { Nanoc::Core::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::ItemRep#0<item=Nanoc::Core::Item#1<content=Nanoc::Core::TextualContent#2<String#3<asdf>>,attributes=Hash#4<>,identifier=Nanoc::Core::Identifier#5<String#6</foo.md>>>,name=Symbol#7<pdf>>') }
  end

  context 'Nanoc::Core::Context' do
    let(:obj) { Nanoc::Core::Context.new(foo: 123) }

    it { is_expected.to match(/\ANanoc::Core::Context#0<@foo=(Fixnum|Integer)#1<123>,>\z/) }
  end

  context 'Nanoc::Core::CodeSnippet' do
    let(:obj) { Nanoc::Core::CodeSnippet.new('asdf', '/bob.rb') }

    it { is_expected.to eql('Nanoc::Core::CodeSnippet#0<String#1<asdf>>') }
  end

  context 'Nanoc::Core::CompilationItemView' do
    let(:obj) { Nanoc::Core::CompilationItemView.new(item, nil) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::CompilationItemView#0<Nanoc::Core::Item#1<content=Nanoc::Core::TextualContent#2<String#3<asdf>>,attributes=Hash#4<>,identifier=Nanoc::Core::Identifier#5<String#6</foo.md>>>>') }
  end

  context 'Nanoc::Core::BasicItemRepView' do
    let(:obj) { Nanoc::Core::BasicItemRepView.new(rep, nil) }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::BasicItemRepView#0<Nanoc::Core::ItemRep#1<item=Nanoc::Core::Item#2<content=Nanoc::Core::TextualContent#3<String#4<asdf>>,attributes=Hash#5<>,identifier=Nanoc::Core::Identifier#6<String#7</foo.md>>>,name=Symbol#8<pdf>>>') }
  end

  context 'Nanoc::Core::CompilationItemRepView' do
    let(:obj) { Nanoc::Core::CompilationItemRepView.new(rep, nil) }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::CompilationItemRepView#0<Nanoc::Core::ItemRep#1<item=Nanoc::Core::Item#2<content=Nanoc::Core::TextualContent#3<String#4<asdf>>,attributes=Hash#5<>,identifier=Nanoc::Core::Identifier#6<String#7</foo.md>>>,name=Symbol#8<pdf>>>') }
  end

  context 'Nanoc::Core::BasicItemView' do
    let(:obj) { Nanoc::Core::BasicItemView.new(item, nil) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::BasicItemView#0<Nanoc::Core::Item#1<content=Nanoc::Core::TextualContent#2<String#3<asdf>>,attributes=Hash#4<>,identifier=Nanoc::Core::Identifier#5<String#6</foo.md>>>>') }
  end

  context 'Nanoc::Core::LayoutView' do
    let(:obj) { Nanoc::Core::LayoutView.new(layout, nil) }
    let(:layout) { Nanoc::Core::Layout.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Core::LayoutView#0<Nanoc::Core::Layout#1<content=Nanoc::Core::TextualContent#2<String#3<asdf>>,attributes=Hash#4<>,identifier=Nanoc::Core::Identifier#5<String#6</foo.md>>>>') }
  end

  context 'Nanoc::Core::ConfigView' do
    let(:obj) { Nanoc::Core::ConfigView.new(config, nil) }
    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }

    it { is_expected.to eql('Nanoc::Core::ConfigView#0<Nanoc::Core::Configuration#1<Symbol#2<foo>=String#3<bar>,>>') }
  end

  context 'Nanoc::Core::ItemCollectionWithRepsView' do
    let(:obj) { Nanoc::Core::ItemCollectionWithRepsView.new(wrapped, nil) }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }

    let(:wrapped) do
      Nanoc::Core::ItemCollection.new(
        config,
        [
          Nanoc::Core::Item.new('foo', {}, '/foo.md'),
          Nanoc::Core::Item.new('bar', {}, '/bar.md'),
        ],
      )
    end

    it { is_expected.to eql('Nanoc::Core::ItemCollectionWithRepsView#0<Nanoc::Core::ItemCollection#1<Nanoc::Core::Item#2<content=Nanoc::Core::TextualContent#3<String#4<foo>>,attributes=Hash#5<>,identifier=Nanoc::Core::Identifier#6<String#7</foo.md>>>,Nanoc::Core::Item#8<content=Nanoc::Core::TextualContent#9<String#10<bar>>,attributes=@5,identifier=Nanoc::Core::Identifier#11<String#12</bar.md>>>,>>') }
  end

  context 'Nanoc::Core::ItemCollectionWithoutRepsView' do
    let(:obj) { Nanoc::Core::ItemCollectionWithoutRepsView.new(wrapped, nil) }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }

    let(:wrapped) do
      Nanoc::Core::ItemCollection.new(
        config,
        [
          Nanoc::Core::Item.new('foo', {}, '/foo.md'),
          Nanoc::Core::Item.new('bar', {}, '/bar.md'),
        ],
      )
    end

    it { is_expected.to eql('Nanoc::Core::ItemCollectionWithoutRepsView#0<Nanoc::Core::ItemCollection#1<Nanoc::Core::Item#2<content=Nanoc::Core::TextualContent#3<String#4<foo>>,attributes=Hash#5<>,identifier=Nanoc::Core::Identifier#6<String#7</foo.md>>>,Nanoc::Core::Item#8<content=Nanoc::Core::TextualContent#9<String#10<bar>>,attributes=@5,identifier=Nanoc::Core::Identifier#11<String#12</bar.md>>>,>>') }
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

    it { is_expected.to match(/\A#<Class:0x[0-9a-f]+>#0<.*>\z/) }
  end

  context 'other non-marshal-able classes' do
    let(:obj) { proc {} }

    it { is_expected.to match(/\AProc#0<#<Proc:0x.*>>\z/) }
  end
end
