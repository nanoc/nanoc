# frozen_string_literal: true

describe Nanoc::RuleDSL::RoutingRule do
  # TODO: Remove duplication between Rule and RoutingRule
  # TODO: Create CompilationRule

  subject(:rule) do
    described_class.new(pattern, :xml, block)
  end

  let(:pattern) { Nanoc::Int::Pattern.from(%r{/(.*)/(.*)/}) }
  let(:block) { proc {} }

  describe '#matches' do
    subject { rule.send(:matches, identifier) }

    context 'does not match' do
      let(:identifier) { '/moo/' }
      it { is_expected.to be_nil }
    end

    context 'matches' do
      let(:identifier) { '/anything/else/' }
      it { is_expected.to eql(%w[anything else]) }
    end
  end

  describe '#initialize' do
    context 'with snapshot_name' do
      subject { described_class.new(pattern, :xml, proc {}, snapshot_name: :donkey) }

      its(:rep_name) { is_expected.to eql(:xml) }
      its(:pattern) { is_expected.to eql(pattern) }
      its(:snapshot_name) { is_expected.to eql(:donkey) }
    end

    context 'without snapshot_name' do
      subject { described_class.new(pattern, :xml, proc {}) }

      its(:rep_name) { is_expected.to eql(:xml) }
      its(:pattern) { is_expected.to eql(pattern) }
      its(:snapshot_name) { is_expected.to be_nil }
    end
  end

  describe '#applicable_to?' do
    subject { rule.applicable_to?(item) }

    let(:item) { Nanoc::Int::Item.new('', {}, '/foo.md') }

    context 'pattern matches' do
      let(:pattern) { Nanoc::Int::Pattern.from(%r{^/foo.*}) }
      it { is_expected.to be }
    end

    context 'pattern does not match' do
      let(:pattern) { Nanoc::Int::Pattern.from(%r{^/bar.*}) }
      it { is_expected.not_to be }
    end
  end

  describe '#apply_to' do
    subject { rule.apply_to(rep, site: site, view_context: view_context) }

    let(:block) do
      proc { self }
    end

    let(:item) { Nanoc::Int::Item.new('', {}, '/foo.md') }
    let(:rep) { Nanoc::Int::ItemRep.new(item, :amazings) }

    let(:site) { Nanoc::Int::Site.new(config: config, data_source: data_source, code_snippets: []) }
    let(:data_source) { Nanoc::Int::InMemDataSource.new(items, layouts) }
    let(:config) { Nanoc::Int::Configuration.new }
    let(:view_context) { Nanoc::ViewContextForPreCompilation.new(items: items) }
    let(:items) { Nanoc::Int::ItemCollection.new(config, []) }
    let(:layouts) { Nanoc::Int::LayoutCollection.new(config, []) }

    it 'returns a generic context' do
      # FIXME: Create RoutingRuleContext
      expect(subject.class).to eq(Nanoc::Int::Context)
    end

    it 'makes rep accessible' do
      expect(subject.instance_eval { rep }.unwrap).to eql(rep)
      expect(subject.instance_eval { @rep }.unwrap).to eql(rep)
    end

    it 'makes item_rep accessible' do
      expect(subject.instance_eval { item_rep }.unwrap).to eql(rep)
      expect(subject.instance_eval { @item_rep }.unwrap).to eql(rep)
    end

    it 'makes item accessible' do
      expect(subject.instance_eval { item }.unwrap).to eql(item)
      expect(subject.instance_eval { @item }.unwrap).to eql(item)
    end

    it 'makes items accessible' do
      expect(subject.instance_eval { items }.unwrap).to eql(items)
      expect(subject.instance_eval { @items }.unwrap).to eql(items)
    end

    it 'makes layouts accessible' do
      expect(subject.instance_eval { layouts }.unwrap).to eql(layouts)
      expect(subject.instance_eval { @layouts }.unwrap).to eql(layouts)
    end

    it 'makes config accessible' do
      expect(subject.instance_eval { config }.unwrap).to eql(config)
      expect(subject.instance_eval { @config }.unwrap).to eql(config)
    end
  end
end
