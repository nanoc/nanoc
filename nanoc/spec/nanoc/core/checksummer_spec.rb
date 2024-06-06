# frozen_string_literal: true

# NOTE: this spec checks all the bits that aren’t in Core.

describe Nanoc::Core::Checksummer do
  subject { described_class.calc(obj, Nanoc::Core::Checksummer::VerboseDigest) }

  context 'Nanoc::RuleDSL::RulesCollection' do
    let(:obj) do
      Nanoc::RuleDSL::RulesCollection.new.tap { |rc| rc.data = data }
    end

    let(:data) { 'STUFF!' }

    it { is_expected.to eql('Nanoc::RuleDSL::RulesCollection#0<String#1<STUFF!>>') }
  end

  context 'Nanoc::RuleDSL::CompilationRuleContext' do
    let(:obj) { Nanoc::RuleDSL::CompilationRuleContext.new(rep:, site:, recorder:, view_context:) }

    let(:rep) { Nanoc::Core::ItemRep.new(item, :pdf) }
    let(:item) { Nanoc::Core::Item.new('stuff', {}, '/stuff.md') }

    let(:site) do
      Nanoc::Core::Site.new(
        config:,
        code_snippets:,
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )
    end

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { 'foo' => 'bar' }) }
    let(:code_snippets) { [Nanoc::Core::CodeSnippet.new('asdf', '/bob.rb')] }
    let(:items) { Nanoc::Core::ItemCollection.new(config, [item]) }
    let(:layouts) { Nanoc::Core::LayoutCollection.new(config, [Nanoc::Core::Layout.new('asdf', {}, '/foo.md')]) }

    let(:recorder) { Nanoc::RuleDSL::ActionRecorder.new(rep) }
    let(:view_context) { Nanoc::Core::ViewContextForPreCompilation.new(items:) }

    let(:expected_item_checksum) { 'Nanoc::Core::Item#2<content=Nanoc::Core::TextualContent#3<String#4<stuff>>,attributes=Hash#5<>,identifier=Nanoc::Core::Identifier#6<String#7</stuff.md>>>' }
    let(:expected_item_rep_checksum) { 'Nanoc::Core::ItemRep#9<item=@2,name=Symbol#10<pdf>>' }
    let(:expected_layout_checksum) { 'Nanoc::Core::Layout#15<content=Nanoc::Core::TextualContent#16<String#17<asdf>>,attributes=@5,identifier=Nanoc::Core::Identifier#18<String#19</foo.md>>>' }
    let(:expected_config_checksum) { 'Nanoc::Core::Configuration#21<Symbol#22<foo>=String#23<bar>,>' }

    let(:expected_checksum) do
      [
        'Nanoc::RuleDSL::CompilationRuleContext#0<',
        'item=',
        'Nanoc::Core::BasicItemView#1<' + expected_item_checksum + '>',
        ',rep=',
        'Nanoc::Core::BasicItemRepView#8<' + expected_item_rep_checksum + '>',
        ',items=',
        'Nanoc::Core::ItemCollectionWithoutRepsView#11<Nanoc::Core::ItemCollection#12<@2,>>',
        ',layouts=',
        'Nanoc::Core::LayoutCollectionView#13<Nanoc::Core::LayoutCollection#14<' + expected_layout_checksum + ',>>',
        ',config=',
        'Nanoc::Core::ConfigView#20<' + expected_config_checksum + '>',
        '>',
      ].join('')
    end

    it { is_expected.to eql(expected_checksum) }
  end

  context 'Sass::Importers::Filesystem' do
    let(:obj) { Sass::Importers::Filesystem.new('/foo') }

    before { require 'sass' }

    it { is_expected.to match(%r{\ASass::Importers::Filesystem#0<root=(C:)?/foo>\z}) }
  end
end
