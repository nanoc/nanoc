# frozen_string_literal: true

describe(Nanoc::RuleDSL::RoutingRuleContext) do
  subject(:rule_context) do
    described_class.new(rep: rep, site: site, view_context: view_context)
  end

  let(:item_identifier) { Nanoc::Identifier.new('/foo.md') }
  let(:item) { Nanoc::Int::Item.new('content', {}, item_identifier) }
  let(:config) { Nanoc::Int::Configuration.new }
  let(:items) { Nanoc::Int::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Int::LayoutCollection.new(config) }

  let(:site) do
    Nanoc::Int::Site.new(
      config: config,
      code_snippets: [],
      data_source: data_source,
    )
  end

  let(:data_source) do
    Nanoc::Int::InMemDataSource.new(items, layouts)
  end

  let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }
  let(:reps) { double(:reps) }
  let(:compilation_context) { double(:compilation_context) }

  let(:view_context) do
    Nanoc::ViewContextForPreCompilation.new(items: items)
  end

  let(:dependency_tracker) { double(:dependency_tracker) }
  let(:snapshot_repo) { double(:snapshot_repo) }

  describe '#initialize' do
    it 'wraps objects in view classes' do
      expect(subject.rep.class).to eql(Nanoc::BasicItemRepView)
      expect(subject.item.class).to eql(Nanoc::BasicItemView)
      expect(subject.config.class).to eql(Nanoc::ConfigView)
      expect(subject.layouts.class).to eql(Nanoc::LayoutCollectionView)
      expect(subject.items.class).to eql(Nanoc::ItemCollectionWithoutRepsView)
    end

    it 'contains the right objects' do
      expect(rule_context.rep.unwrap).to eql(rep)
      expect(rule_context.item.unwrap).to eql(item)
      expect(rule_context.config.unwrap).to eql(config)
      expect(rule_context.layouts.unwrap).to eql(layouts)
      expect(rule_context.items.unwrap).to eql(items)
    end
  end

  describe '#item' do
    subject { rule_context.item }

    it 'is a view without reps access' do
      expect(subject.class).to eql(Nanoc::BasicItemView)
    end

    it 'contains the right item' do
      expect(subject.unwrap).to eql(item)
    end

    context 'with legacy identifier and children/parent' do
      let(:item_identifier) { Nanoc::Identifier.new('/foo/', type: :legacy) }

      let(:parent_identifier) { Nanoc::Identifier.new('/', type: :legacy) }
      let(:parent) { Nanoc::Int::Item.new('parent', {}, parent_identifier) }

      let(:child_identifier) { Nanoc::Identifier.new('/foo/bar/', type: :legacy) }
      let(:child) { Nanoc::Int::Item.new('child', {}, child_identifier) }

      let(:items) do
        Nanoc::Int::ItemCollection.new(config, [item, parent, child])
      end

      it 'has a parent' do
        expect(subject.parent.unwrap).to eql(parent)
      end

      it 'wraps the parent in a view without reps access' do
        expect(subject.parent.class).to eql(Nanoc::BasicItemView)
        expect(subject.parent).not_to respond_to(:compiled_content)
        expect(subject.parent).not_to respond_to(:path)
        expect(subject.parent).not_to respond_to(:reps)
      end

      it 'has children' do
        expect(subject.children.map(&:unwrap)).to eql([child])
      end

      it 'wraps the children in a view without reps access' do
        expect(subject.children.map(&:class)).to eql([Nanoc::BasicItemView])
        expect(subject.children[0]).not_to respond_to(:compiled_content)
        expect(subject.children[0]).not_to respond_to(:path)
        expect(subject.children[0]).not_to respond_to(:reps)
      end
    end
  end

  describe '#items' do
    subject { rule_context.items }

    let(:item_identifier) { Nanoc::Identifier.new('/foo/', type: :legacy) }

    let(:parent_identifier) { Nanoc::Identifier.new('/', type: :legacy) }
    let(:parent) { Nanoc::Int::Item.new('parent', {}, parent_identifier) }

    let(:child_identifier) { Nanoc::Identifier.new('/foo/bar/', type: :legacy) }
    let(:child) { Nanoc::Int::Item.new('child', {}, child_identifier) }

    let(:items) do
      Nanoc::Int::ItemCollection.new(config, [item, parent, child])
    end

    it 'is a view without reps access' do
      expect(subject.class).to eql(Nanoc::ItemCollectionWithoutRepsView)
    end

    it 'contains all items' do
      expect(subject.unwrap).to match_array([item, parent, child])
    end

    it 'provides no rep access' do
      allow(dependency_tracker).to receive(:bounce).and_return(nil)

      expect(subject['/']).not_to be_nil
      expect(subject['/']).not_to respond_to(:compiled_content)
      expect(subject['/']).not_to respond_to(:path)
      expect(subject['/']).not_to respond_to(:reps)

      expect(subject['/foo/']).not_to be_nil
      expect(subject['/foo/']).not_to respond_to(:compiled_content)
      expect(subject['/foo/']).not_to respond_to(:path)
      expect(subject['/foo/']).not_to respond_to(:reps)

      expect(subject['/foo/bar/']).not_to be_nil
      expect(subject['/foo/bar/']).not_to respond_to(:compiled_content)
      expect(subject['/foo/bar/']).not_to respond_to(:path)
      expect(subject['/foo/bar/']).not_to respond_to(:reps)
    end
  end
end
