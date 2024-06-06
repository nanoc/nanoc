# frozen_string_literal: true

shared_examples 'a rule context' do
  let(:item_identifier) { Nanoc::Core::Identifier.new('/foo.md') }
  let(:item) { Nanoc::Core::Item.new('content', {}, item_identifier) }
  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd) }
  let(:items) { Nanoc::Core::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source:,
    )
  end

  let(:data_source) do
    Nanoc::Core::InMemoryDataSource.new(items, layouts)
  end

  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }
  let(:reps) { double(:reps) }
  let(:compilation_context) { double(:compilation_context) }

  let(:view_context) do
    Nanoc::Core::ViewContextForPreCompilation.new(items:)
  end

  let(:dependency_tracker) { Nanoc::Core::DependencyTracker::Null.new }

  describe '#initialize' do
    it 'wraps objects in view classes' do
      expect(subject.rep.class).to eql(Nanoc::Core::BasicItemRepView)
      expect(subject.item.class).to eql(Nanoc::Core::BasicItemView)
      expect(subject.config.class).to eql(Nanoc::Core::ConfigView)
      expect(subject.layouts.class).to eql(Nanoc::Core::LayoutCollectionView)
      expect(subject.items.class).to eql(Nanoc::Core::ItemCollectionWithoutRepsView)
    end

    it 'contains the right objects' do
      expect(rule_context.rep._unwrap).to eql(rep)
      expect(rule_context.item._unwrap).to eql(item)
      expect(rule_context.config._unwrap).to eql(config)
      expect(rule_context.layouts._unwrap).to eql(layouts)
      expect(rule_context.items._unwrap).to eql(items)
    end
  end

  describe '#item' do
    subject { rule_context.item }

    it 'is a view without reps access' do
      expect(subject.class).to eql(Nanoc::Core::BasicItemView)
    end

    it 'contains the right item' do
      expect(subject._unwrap).to eql(item)
    end

    context 'with legacy identifier and children/parent' do
      let(:item_identifier) { Nanoc::Core::Identifier.new('/foo/', type: :legacy) }

      let(:parent_identifier) { Nanoc::Core::Identifier.new('/', type: :legacy) }
      let(:parent) { Nanoc::Core::Item.new('parent', {}, parent_identifier) }

      let(:child_identifier) { Nanoc::Core::Identifier.new('/foo/bar/', type: :legacy) }
      let(:child) { Nanoc::Core::Item.new('child', {}, child_identifier) }

      let(:items) do
        Nanoc::Core::ItemCollection.new(config, [item, parent, child])
      end

      it 'has a parent' do
        expect(subject.parent._unwrap).to eql(parent)
      end

      it 'wraps the parent in a view without reps access' do
        expect(subject.parent.class).to eql(Nanoc::Core::BasicItemView)
        expect(subject.parent).not_to respond_to(:compiled_content)
        expect(subject.parent).not_to respond_to(:path)
        expect(subject.parent).not_to respond_to(:reps)
      end

      it 'has children' do
        expect(subject.children.map(&:_unwrap)).to eql([child])
      end

      it 'wraps the children in a view without reps access' do
        expect(subject.children.map(&:class)).to eql([Nanoc::Core::BasicItemView])
        expect(subject.children[0]).not_to respond_to(:compiled_content)
        expect(subject.children[0]).not_to respond_to(:path)
        expect(subject.children[0]).not_to respond_to(:reps)
      end
    end
  end

  describe '#items' do
    subject { rule_context.items }

    let(:item_identifier) { Nanoc::Core::Identifier.new('/foo/', type: :legacy) }

    let(:parent_identifier) { Nanoc::Core::Identifier.new('/', type: :legacy) }
    let(:parent) { Nanoc::Core::Item.new('parent', {}, parent_identifier) }

    let(:child_identifier) { Nanoc::Core::Identifier.new('/foo/bar/', type: :legacy) }
    let(:child) { Nanoc::Core::Item.new('child', {}, child_identifier) }

    let(:items) do
      Nanoc::Core::ItemCollection.new(config, [item, parent, child])
    end

    it 'is a view without reps access' do
      expect(subject.class).to eql(Nanoc::Core::ItemCollectionWithoutRepsView)
    end

    it 'contains all items' do
      expect(subject._unwrap).to contain_exactly(item, parent, child)
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

describe(Nanoc::RuleDSL::RoutingRuleContext) do
  subject(:rule_context) do
    described_class.new(rep:, site:, view_context:)
  end

  let(:item_identifier) { Nanoc::Core::Identifier.new('/foo.md') }
  let(:item) { Nanoc::Core::Item.new('content', {}, item_identifier) }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }
  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd) }
  let(:items) { Nanoc::Core::ItemCollection.new(config) }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source:,
    )
  end

  let(:view_context) do
    Nanoc::Core::ViewContextForPreCompilation.new(items:)
  end

  it_behaves_like 'a rule context'
end

describe(Nanoc::RuleDSL::CompilationRuleContext) do
  subject(:rule_context) do
    described_class.new(rep:, site:, recorder:, view_context:)
  end

  let(:item_identifier) { Nanoc::Core::Identifier.new('/foo.md') }
  let(:item) { Nanoc::Core::Item.new('content', {}, item_identifier) }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }
  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd) }
  let(:items) { Nanoc::Core::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source:,
    )
  end

  let(:data_source) do
    Nanoc::Core::InMemoryDataSource.new(items, layouts)
  end

  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }

  let(:view_context) do
    Nanoc::Core::ViewContextForPreCompilation.new(items:)
  end

  let(:recorder) { Nanoc::RuleDSL::ActionRecorder.new(rep) }

  it_behaves_like 'a rule context'

  describe '#filter' do
    subject { rule_context.filter(filter_name, filter_args) }

    let(:filter_name) { :donkey }
    let(:filter_args) { { color: 'grey' } }

    it 'makes a request to the recorder' do
      expect(recorder).to receive(:filter).with(filter_name, filter_args)
      subject
    end
  end

  describe '#layout' do
    subject { rule_context.layout(layout_identifier, extra_filter_args) }

    let(:layout_identifier) { '/default.*' }
    let(:extra_filter_args) { { color: 'grey' } }

    it 'makes a request to the recorder' do
      expect(recorder).to receive(:layout).with(layout_identifier, extra_filter_args)
      subject
    end
  end

  describe '#snapshot' do
    subject { rule_context.snapshot(snapshot_name, path:) }

    let(:snapshot_name) { :for_snippet }
    let(:path) { '/foo.html' }

    it 'makes a request to the recorder' do
      expect(recorder).to receive(:snapshot).with(:for_snippet, path: '/foo.html')
      subject
    end
  end

  describe '#write' do
    context 'with string' do
      context 'calling once' do
        subject { rule_context.write('/foo.html') }

        it 'makes a request to the recorder' do
          expect(recorder).to receive(:snapshot).with(:_0, path: '/foo.html')
          subject
        end
      end

      context 'calling twice' do
        subject do
          rule_context.write('/foo.html')
          rule_context.write('/bar.html')
        end

        it 'makes two requests to the recorder with unique snapshot names' do
          expect(recorder).to receive(:snapshot).with(:_0, path: '/foo.html')
          expect(recorder).to receive(:snapshot).with(:_1, path: '/bar.html')
          subject
        end
      end
    end

    context 'with identifier' do
      context 'calling once' do
        subject { rule_context.write(identifier) }

        let(:identifier) { Nanoc::Core::Identifier.new('/foo.html') }

        it 'makes a request to the recorder' do
          expect(recorder).to receive(:snapshot).with(:_0, path: '/foo.html')
          subject
        end
      end

      context 'calling twice' do
        subject do
          rule_context.write(identifier_a)
          rule_context.write(identifier_b)
        end

        let(:identifier_a) { Nanoc::Core::Identifier.new('/foo.html') }
        let(:identifier_b) { Nanoc::Core::Identifier.new('/bar.html') }

        it 'makes two requests to the recorder with unique snapshot names' do
          expect(recorder).to receive(:snapshot).with(:_0, path: '/foo.html')
          expect(recorder).to receive(:snapshot).with(:_1, path: '/bar.html')
          subject
        end
      end
    end

    context 'with :ext, without period' do
      context 'calling once' do
        subject { rule_context.write(ext: 'html') }

        it 'makes a request to the recorder' do
          expect(recorder).to receive(:snapshot).with(:_0, path: '/foo.html')
          subject
        end
      end

      context 'calling twice' do
        subject do
          rule_context.write(ext: 'html')
          rule_context.write(ext: 'htm')
        end

        it 'makes a request to the recorder' do
          expect(recorder).to receive(:snapshot).with(:_0, path: '/foo.html')
          expect(recorder).to receive(:snapshot).with(:_1, path: '/foo.htm')
          subject
        end
      end
    end

    context 'with :ext, with period' do
      context 'calling once' do
        subject { rule_context.write(ext: '.html') }

        it 'makes a request to the recorder' do
          expect(recorder).to receive(:snapshot).with(:_0, path: '/foo.html')
          subject
        end
      end

      context 'calling twice' do
        subject do
          rule_context.write(ext: '.html')
          rule_context.write(ext: '.htm')
        end

        it 'makes a request to the recorder' do
          expect(recorder).to receive(:snapshot).with(:_0, path: '/foo.html')
          expect(recorder).to receive(:snapshot).with(:_1, path: '/foo.htm')
          subject
        end
      end
    end

    context 'with nil' do
      subject { rule_context.write(nil) }

      it 'makes a request to the recorder' do
        expect(recorder).to receive(:snapshot).with(:_0, path: nil)
        subject
      end
    end
  end
end
