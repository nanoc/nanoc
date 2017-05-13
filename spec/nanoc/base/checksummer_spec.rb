# frozen_string_literal: true

require 'tempfile'

describe Nanoc::Int::Checksummer::VerboseDigest do
  let(:digest) { described_class.new }

  it 'concatenates' do
    digest.update('foo')
    digest.update('bar')
    expect(digest.to_s).to eql('foobar')
  end
end

describe Nanoc::Int::Checksummer::CompactDigest do
  let(:digest) { described_class.new }

  it 'uses SHA1 and Base64' do
    digest.update('foo')
    digest.update('bar')
    expect(digest.to_s).to eql(Digest::SHA1.base64digest('foobar'))
  end
end

describe Nanoc::Int::Checksummer do
  subject { described_class.calc(obj, Nanoc::Int::Checksummer::VerboseDigest) }

  describe '.calc_for_each_attribute_of' do
    let(:obj) { Nanoc::Int::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md') }

    context 'compact' do
      subject do
        described_class.calc_for_each_attribute_of(obj)
      end

      it { is_expected.to have_key(:foo) }
    end

    context 'verbose' do
      subject do
        described_class.calc_for_each_attribute_of(obj, Nanoc::Int::Checksummer::VerboseDigest)
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
      it { is_expected.to match(/\AArray<Proc<#<Proc:0x.*@.*:\d+.*>>,>\z/) }
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
      it { is_expected.to match(/\AHash<String<a>=Proc<#<Proc:0x.*@.*:\d+.*>>,>\z/) }
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

  context 'Nanoc::Identifier' do
    let(:obj) { Nanoc::Identifier.new('/foo.md') }
    it { is_expected.to eql('Nanoc::Identifier<String</foo.md>>') }
  end

  context 'Nanoc::RuleDSL::RulesCollection' do
    let(:obj) do
      Nanoc::RuleDSL::RulesCollection.new.tap { |rc| rc.data = data }
    end

    let(:data) { 'STUFF!' }

    it { is_expected.to eql('Nanoc::RuleDSL::RulesCollection<String<STUFF!>>') }
  end

  context 'Nanoc::Int::CodeSnippet' do
    let(:obj) { Nanoc::Int::CodeSnippet.new('asdf', '/bob.rb') }
    it { is_expected.to eql('Nanoc::Int::CodeSnippet<String<asdf>>') }
  end

  context 'Nanoc::Int::Configuration' do
    let(:obj) { Nanoc::Int::Configuration.new(hash: { 'foo' => 'bar' }) }
    it { is_expected.to eql('Nanoc::Int::Configuration<Symbol<foo>=String<bar>,>') }
  end

  context 'Nanoc::Int::Item' do
    let(:obj) { Nanoc::Int::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md') }

    it { is_expected.to eql('Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<asdf>>,attributes=Hash<Symbol<foo>=String<bar>,>,identifier=Nanoc::Identifier<String</foo.md>>>') }

    context 'binary' do
      let(:filename) { File.expand_path('foo.dat') }
      let(:content) { Nanoc::Int::BinaryContent.new(filename) }
      let(:obj) { Nanoc::Int::Item.new(content, { 'foo' => 'bar' }, '/foo.md') }

      let(:mtime) { 200 }
      let(:data) { 'stuffs' }

      before do
        File.write(content.filename, data)
        File.utime(mtime, mtime, content.filename)
      end

      it { is_expected.to eql('Nanoc::Int::Item<content=Nanoc::Int::BinaryContent<Pathname<6-200>>,attributes=Hash<Symbol<foo>=String<bar>,>,identifier=Nanoc::Identifier<String</foo.md>>>') }
    end

    context 'recursive attributes' do
      before do
        obj.attributes[:foo] = obj
      end

      it { is_expected.to eql('Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<asdf>>,attributes=Hash<Symbol<foo>=Nanoc::Int::Item<recur>,>,identifier=Nanoc::Identifier<String</foo.md>>>') }
    end

    context 'with checksum' do
      let(:obj) { Nanoc::Int::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md', checksum_data: 'abcdef') }

      it { is_expected.to eql('Nanoc::Int::Item<checksum_data=abcdef>') }
    end

    context 'with content checksum' do
      let(:obj) { Nanoc::Int::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md', content_checksum_data: 'con-cs') }

      it { is_expected.to eql('Nanoc::Int::Item<content_checksum_data=con-cs,attributes=Hash<Symbol<foo>=String<bar>,>,identifier=Nanoc::Identifier<String</foo.md>>>') }
    end

    context 'with attributes checksum' do
      let(:obj) { Nanoc::Int::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md', attributes_checksum_data: 'attr-cs') }

      it { is_expected.to eql('Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<asdf>>,attributes_checksum_data=attr-cs,identifier=Nanoc::Identifier<String</foo.md>>>') }
    end
  end

  context 'Nanoc::Int::Layout' do
    let(:obj) { Nanoc::Int::Layout.new('asdf', { 'foo' => 'bar' }, '/foo.md') }

    it { is_expected.to eql('Nanoc::Int::Layout<content=Nanoc::Int::TextualContent<String<asdf>>,attributes=Hash<Symbol<foo>=String<bar>,>,identifier=Nanoc::Identifier<String</foo.md>>>') }

    context 'recursive attributes' do
      before do
        obj.attributes[:foo] = obj
      end

      it { is_expected.to eql('Nanoc::Int::Layout<content=Nanoc::Int::TextualContent<String<asdf>>,attributes=Hash<Symbol<foo>=Nanoc::Int::Layout<recur>,>,identifier=Nanoc::Identifier<String</foo.md>>>') }
    end

    context 'with checksum' do
      let(:obj) { Nanoc::Int::Layout.new('asdf', { 'foo' => 'bar' }, '/foo.md', checksum_data: 'abcdef') }

      it { is_expected.to eql('Nanoc::Int::Layout<checksum_data=abcdef>') }
    end
  end

  context 'Nanoc::ItemWithRepsView' do
    let(:obj) { Nanoc::ItemWithRepsView.new(item, nil) }
    let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::ItemWithRepsView<Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</foo.md>>>>') }
  end

  context 'Nanoc::Int::ItemRep' do
    let(:obj) { Nanoc::Int::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::Int::ItemRep<item=Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</foo.md>>>,name=Symbol<pdf>>') }
  end

  context 'Nanoc::ItemRepView' do
    let(:obj) { Nanoc::ItemRepView.new(rep, :_unused_context) }
    let(:rep) { Nanoc::Int::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::ItemRepView<Nanoc::Int::ItemRep<item=Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</foo.md>>>,name=Symbol<pdf>>>') }
  end

  context 'Nanoc::ItemWithoutRepsView' do
    let(:obj) { Nanoc::ItemWithoutRepsView.new(item, nil) }
    let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::ItemWithoutRepsView<Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</foo.md>>>>') }
  end

  context 'Nanoc::LayoutView' do
    let(:obj) { Nanoc::LayoutView.new(layout, nil) }
    let(:layout) { Nanoc::Int::Layout.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::LayoutView<Nanoc::Int::Layout<content=Nanoc::Int::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</foo.md>>>>') }
  end

  context 'Nanoc::ConfigView' do
    let(:obj) { Nanoc::ConfigView.new(config, nil) }
    let(:config) { Nanoc::Int::Configuration.new(hash: { 'foo' => 'bar' }) }

    it { is_expected.to eql('Nanoc::ConfigView<Nanoc::Int::Configuration<Symbol<foo>=String<bar>,>>') }
  end

  context 'Nanoc::ItemCollectionWithRepsView' do
    let(:obj) { Nanoc::ItemCollectionWithRepsView.new(wrapped, nil) }

    let(:config) { Nanoc::Int::Configuration.new(hash: { 'foo' => 'bar' }) }

    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(
        config,
        [
          Nanoc::Int::Item.new('foo', {}, '/foo.md'),
          Nanoc::Int::Item.new('bar', {}, '/foo.md'),
        ],
      )
    end

    it { is_expected.to eql('Nanoc::ItemCollectionWithRepsView<Nanoc::Int::IdentifiableCollection<Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<foo>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</foo.md>>>,Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<bar>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</foo.md>>>,>>') }
  end

  context 'Nanoc::ItemCollectionWithoutRepsView' do
    let(:obj) { Nanoc::ItemCollectionWithoutRepsView.new(wrapped, nil) }

    let(:config) { Nanoc::Int::Configuration.new(hash: { 'foo' => 'bar' }) }

    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(
        config,
        [
          Nanoc::Int::Item.new('foo', {}, '/foo.md'),
          Nanoc::Int::Item.new('bar', {}, '/foo.md'),
        ],
      )
    end

    it { is_expected.to eql('Nanoc::ItemCollectionWithoutRepsView<Nanoc::Int::IdentifiableCollection<Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<foo>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</foo.md>>>,Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<bar>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</foo.md>>>,>>') }
  end

  context 'Nanoc::RuleDSL::RuleContext' do
    let(:obj) { Nanoc::RuleDSL::RuleContext.new(rep: rep, site: site, executor: executor, view_context: view_context) }

    let(:rep) { Nanoc::Int::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Int::Item.new('stuff', {}, '/stuff.md') }

    let(:site) do
      Nanoc::Int::Site.new(
        config: config,
        code_snippets: code_snippets,
        data_source: Nanoc::Int::InMemDataSource.new(items, layouts),
      )
    end

    let(:config) { Nanoc::Int::Configuration.new(hash: { 'foo' => 'bar' }) }
    let(:code_snippets) { [Nanoc::Int::CodeSnippet.new('asdf', '/bob.rb')] }
    let(:items) { [item] }
    let(:layouts) { [Nanoc::Int::Layout.new('asdf', {}, '/foo.md')] }

    let(:executor) { :_unused_ }
    let(:view_context) { :_unused_ }

    let(:expected_item_checksum) { 'Nanoc::Int::Item<content=Nanoc::Int::TextualContent<String<stuff>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</stuff.md>>>' }
    let(:expected_item_rep_checksum) { 'Nanoc::Int::ItemRep<item=' + expected_item_checksum + ',name=Symbol<pdf>>' }
    let(:expected_layout_checksum) { 'Nanoc::Int::Layout<content=Nanoc::Int::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Identifier<String</foo.md>>>' }
    let(:expected_config_checksum) { 'Nanoc::Int::Configuration<Symbol<foo>=String<bar>,>' }

    let(:expected_checksum) do
      [
        'Nanoc::RuleDSL::RuleContext<',
        'item=',
        'Nanoc::ItemWithoutRepsView<' + expected_item_checksum + '>',
        ',rep=',
        'Nanoc::ItemRepView<' + expected_item_rep_checksum + '>',
        ',items=',
        'Nanoc::ItemCollectionWithoutRepsView<Array<' + expected_item_checksum + ',>>',
        ',layouts=',
        'Nanoc::LayoutCollectionView<Array<' + expected_layout_checksum + ',>>',
        ',config=',
        'Nanoc::ConfigView<' + expected_config_checksum + '>',
        '>',
      ].join('')
    end

    it { is_expected.to eql(expected_checksum) }
  end

  context 'Nanoc::Int::Context' do
    let(:obj) { Nanoc::Int::Context.new(foo: 123) }

    it { is_expected.to match(/\ANanoc::Int::Context<@foo=(Fixnum|Integer)<123>,>\z/) }
  end

  context 'Sass::Importers::Filesystem' do
    let(:obj) { Sass::Importers::Filesystem.new('/foo') }

    before { require 'sass' }

    it { is_expected.to eql('Sass::Importers::Filesystem<root=/foo>') }
  end

  context 'other marshal-able classes' do
    let(:obj) { klass.new('hello') }

    let(:klass) do
      Class.new do
        def initialize(a)
          @a = a
        end
      end
    end

    it { is_expected.to match(/\A#<Class:0x[0-9a-f]+><.*>\z/) }
  end

  context 'other non-marshal-able classes' do
    let(:obj) { proc {} }
    it { is_expected.to match(/\AProc<#<Proc:0x.*@.*:\d+.*>>\z/) }
  end
end
