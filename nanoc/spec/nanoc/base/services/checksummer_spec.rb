# frozen_string_literal: true

# NOTE: this spec checks all the bits that aren’t in Core.

describe Nanoc::Core::Checksummer do
  subject { described_class.calc(obj, Nanoc::Core::Checksummer::VerboseDigest) }

  context 'Nanoc::RuleDSL::RulesCollection' do
    let(:obj) do
      Nanoc::RuleDSL::RulesCollection.new.tap { |rc| rc.data = data }
    end

    let(:data) { 'STUFF!' }

    it { is_expected.to eql('Nanoc::RuleDSL::RulesCollection<String<STUFF!>>') }
  end

  context 'Nanoc::Core::CodeSnippet' do
    let(:obj) { Nanoc::Core::CodeSnippet.new('asdf', '/bob.rb') }
    it { is_expected.to eql('Nanoc::Core::CodeSnippet<String<asdf>>') }
  end

  context 'Nanoc::CompilationItemView' do
    let(:obj) { Nanoc::CompilationItemView.new(item, nil) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::CompilationItemView<Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>>') }
  end

  context 'Nanoc::BasicItemRepView' do
    let(:obj) { Nanoc::BasicItemRepView.new(rep, :_unused_context) }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::BasicItemRepView<Nanoc::Core::ItemRep<item=Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,name=Symbol<pdf>>>') }
  end

  context 'Nanoc::CompilationItemRepView' do
    let(:obj) { Nanoc::CompilationItemRepView.new(rep, :_unused_context) }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::CompilationItemRepView<Nanoc::Core::ItemRep<item=Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,name=Symbol<pdf>>>') }
  end

  context 'Nanoc::BasicItemView' do
    let(:obj) { Nanoc::BasicItemView.new(item, nil) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::BasicItemView<Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>>') }
  end

  context 'Nanoc::LayoutView' do
    let(:obj) { Nanoc::LayoutView.new(layout, nil) }
    let(:layout) { Nanoc::Core::Layout.new('asdf', {}, '/foo.md') }

    it { is_expected.to eql('Nanoc::LayoutView<Nanoc::Core::Layout<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>>') }
  end

  context 'Nanoc::ConfigView' do
    let(:obj) { Nanoc::ConfigView.new(config, nil) }
    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }

    it { is_expected.to eql('Nanoc::ConfigView<Nanoc::Core::Configuration<Symbol<foo>=String<bar>,>>') }
  end

  context 'Nanoc::ItemCollectionWithRepsView' do
    let(:obj) { Nanoc::ItemCollectionWithRepsView.new(wrapped, nil) }

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

    it { is_expected.to eql('Nanoc::ItemCollectionWithRepsView<Nanoc::Core::ItemCollection<Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<foo>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<bar>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,>>') }
  end

  context 'Nanoc::ItemCollectionWithoutRepsView' do
    let(:obj) { Nanoc::ItemCollectionWithoutRepsView.new(wrapped, nil) }

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

    it { is_expected.to eql('Nanoc::ItemCollectionWithoutRepsView<Nanoc::Core::ItemCollection<Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<foo>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<bar>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>,>>') }
  end

  context 'Nanoc::RuleDSL::CompilationRuleContext' do
    let(:obj) { Nanoc::RuleDSL::CompilationRuleContext.new(rep: rep, site: site, recorder: recorder, view_context: view_context) }

    let(:rep) { Nanoc::Core::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Core::Item.new('stuff', {}, '/stuff.md') }

    let(:site) do
      Nanoc::Int::Site.new(
        config: config,
        code_snippets: code_snippets,
        data_source: Nanoc::Int::InMemDataSource.new(items, layouts),
      )
    end

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }
    let(:code_snippets) { [Nanoc::Core::CodeSnippet.new('asdf', '/bob.rb')] }
    let(:items) { Nanoc::Core::ItemCollection.new(config, [item]) }
    let(:layouts) { [Nanoc::Core::Layout.new('asdf', {}, '/foo.md')] }

    let(:recorder) { Nanoc::RuleDSL::ActionRecorder.new(rep) }
    let(:view_context) { Nanoc::ViewContextForPreCompilation.new(items: items) }

    let(:expected_item_checksum) { 'Nanoc::Core::Item<content=Nanoc::Core::TextualContent<String<stuff>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</stuff.md>>>' }
    let(:expected_item_rep_checksum) { 'Nanoc::Core::ItemRep<item=' + expected_item_checksum + ',name=Symbol<pdf>>' }
    let(:expected_layout_checksum) { 'Nanoc::Core::Layout<content=Nanoc::Core::TextualContent<String<asdf>>,attributes=Hash<>,identifier=Nanoc::Core::Identifier<String</foo.md>>>' }
    let(:expected_config_checksum) { 'Nanoc::Core::Configuration<Symbol<foo>=String<bar>,>' }

    let(:expected_checksum) do
      [
        'Nanoc::RuleDSL::CompilationRuleContext<',
        'item=',
        'Nanoc::BasicItemView<' + expected_item_checksum + '>',
        ',rep=',
        'Nanoc::BasicItemRepView<' + expected_item_rep_checksum + '>',
        ',items=',
        'Nanoc::ItemCollectionWithoutRepsView<Nanoc::Core::ItemCollection<' + expected_item_checksum + ',>>',
        ',layouts=',
        'Nanoc::LayoutCollectionView<Array<' + expected_layout_checksum + ',>>',
        ',config=',
        'Nanoc::ConfigView<' + expected_config_checksum + '>',
        '>',
      ].join('')
    end

    it { is_expected.to eql(expected_checksum) }
  end

  context 'Sass::Importers::Filesystem' do
    let(:obj) { Sass::Importers::Filesystem.new('/foo') }

    before { require 'sass' }

    it { is_expected.to match(%r{\ASass::Importers::Filesystem<root=(C:)?/foo>\z}) }
  end
end
