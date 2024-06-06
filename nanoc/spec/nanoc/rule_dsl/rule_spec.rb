# frozen_string_literal: true

shared_examples 'a generic rule' do
  subject(:rule) do
    described_class.new(pattern, :xml, block)
  end

  let(:pattern) { Nanoc::Core::Pattern.from(%r{/(.*)/(.*)/}) }
  let(:block) { proc {} }

  describe '#matches' do
    subject { rule.matches(identifier) }

    context 'does not match' do
      let(:identifier) { Nanoc::Core::Identifier.new('/moo/', type: :legacy) }

      it { is_expected.to be_nil }
    end

    context 'matches' do
      let(:identifier) { Nanoc::Core::Identifier.new('/foo/bar/', type: :legacy) }

      it { is_expected.to eql(%w[foo bar]) }
    end
  end

  describe '#initialize' do
    subject { rule }

    its(:rep_name) { is_expected.to be(:xml) }
    its(:pattern) { is_expected.to eql(pattern) }
  end

  describe '#applicable_to?' do
    subject { rule.applicable_to?(item) }

    let(:item) { Nanoc::Core::Item.new('', {}, '/foo.md') }

    context 'pattern matches' do
      let(:pattern) { Nanoc::Core::Pattern.from(%r{^/foo.*}) }

      it { is_expected.to be }
    end

    context 'pattern does not match' do
      let(:pattern) { Nanoc::Core::Pattern.from(%r{^/bar.*}) }

      it { is_expected.not_to be }
    end
  end
end

shared_examples 'Rule#apply_to' do
  let(:block) do
    proc { self }
  end

  let(:item) { Nanoc::Core::Item.new('', {}, '/foo.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :amazings) }

  let(:site) { Nanoc::Core::Site.new(config:, data_source:, code_snippets: []) }
  let(:data_source) { Nanoc::Core::InMemoryDataSource.new(items, layouts) }
  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd) }
  let(:view_context) { Nanoc::Core::ViewContextForPreCompilation.new(items:) }
  let(:items) { Nanoc::Core::ItemCollection.new(config, []) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config, []) }

  it 'makes rep accessible' do
    expect(subject.instance_eval { rep }._unwrap).to eql(rep)
    expect(subject.instance_eval { @rep }._unwrap).to eql(rep)
  end

  it 'makes item_rep accessible' do
    expect(subject.instance_eval { item_rep }._unwrap).to eql(rep)
    expect(subject.instance_eval { @item_rep }._unwrap).to eql(rep)
  end

  it 'makes item accessible' do
    expect(subject.instance_eval { item }._unwrap).to eql(item)
    expect(subject.instance_eval { @item }._unwrap).to eql(item)
  end

  it 'makes items accessible' do
    expect(subject.instance_eval { items }._unwrap).to eql(items)
    expect(subject.instance_eval { @items }._unwrap).to eql(items)
  end

  it 'makes layouts accessible' do
    expect(subject.instance_eval { layouts }._unwrap).to eql(layouts)
    expect(subject.instance_eval { @layouts }._unwrap).to eql(layouts)
  end

  it 'makes config accessible' do
    expect(subject.instance_eval { config }._unwrap).to eql(config)
    expect(subject.instance_eval { @config }._unwrap).to eql(config)
  end
end

describe Nanoc::RuleDSL::RoutingRule do
  subject(:rule) do
    described_class.new(pattern, :xml, block)
  end

  let(:pattern) { Nanoc::Core::Pattern.from(%r{/(.*)/(.*)/}) }
  let(:block) { proc {} }

  it_behaves_like 'a generic rule'

  describe '#initialize' do
    context 'without snapshot_name' do
      subject { described_class.new(pattern, :xml, proc {}) }

      its(:rep_name) { is_expected.to be(:xml) }
      its(:pattern) { is_expected.to eql(pattern) }
      its(:snapshot_name) { is_expected.to be_nil }
    end

    context 'with snapshot_name' do
      subject { described_class.new(pattern, :xml, proc {}, snapshot_name: :donkey) }

      its(:rep_name) { is_expected.to be(:xml) }
      its(:pattern) { is_expected.to eql(pattern) }
      its(:snapshot_name) { is_expected.to be(:donkey) }
    end
  end

  describe '#apply_to' do
    subject { rule.apply_to(rep, site:, view_context:) }

    it_behaves_like 'Rule#apply_to'
  end
end

describe Nanoc::RuleDSL::CompilationRule do
  subject(:rule) do
    described_class.new(pattern, :xml, block)
  end

  let(:pattern) { Nanoc::Core::Pattern.from(%r{/(.*)/(.*)/}) }
  let(:block) { proc {} }

  it_behaves_like 'a generic rule'

  describe '#apply_to' do
    subject { rule.apply_to(rep, site:, recorder:, view_context:) }

    let(:recorder) { Nanoc::RuleDSL::ActionRecorder.new(rep) }
    let(:rep) { nil }

    it_behaves_like 'Rule#apply_to'
  end
end
