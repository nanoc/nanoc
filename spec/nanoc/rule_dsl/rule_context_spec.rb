# frozen_string_literal: true

describe(Nanoc::RuleDSL::RuleContext) do
  subject(:rule_context) do
    described_class.new(rep: rep, site: site, executor: executor, view_context: view_context)
  end

  let(:item_identifier) { Nanoc::Identifier.new('/foo.md') }
  let(:item) { Nanoc::Int::Item.new('content', {}, item_identifier) }
  let(:config) { Nanoc::Int::Configuration.new }
  let(:items) { Nanoc::Int::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Int::LayoutCollection.new(config) }

  let(:rep) { double(:rep, item: item) }
  let(:site) { double(:site, items: items, layouts: layouts, config: config) }
  let(:executor) { double(:executor) }
  let(:reps) { double(:reps) }
  let(:compilation_context) { double(:compilation_context) }
  let(:view_context) { Nanoc::ViewContext.new(reps: reps, items: items, dependency_tracker: dependency_tracker, compilation_context: compilation_context, snapshot_repo: snapshot_repo) }
  let(:dependency_tracker) { double(:dependency_tracker) }
  let(:snapshot_repo) { double(:snapshot_repo) }

  describe '#initialize' do
    it 'wraps objects in view classes' do
      expect(subject.rep.class).to eql(Nanoc::ItemRepView)
      expect(subject.item.class).to eql(Nanoc::ItemWithoutRepsView)
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
      expect(subject.class).to eql(Nanoc::ItemWithoutRepsView)
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
        expect(subject.parent.class).to eql(Nanoc::ItemWithoutRepsView)
        expect(subject.parent).not_to respond_to(:compiled_content)
        expect(subject.parent).not_to respond_to(:path)
        expect(subject.parent).not_to respond_to(:reps)
      end

      it 'has children' do
        expect(subject.children.map(&:unwrap)).to eql([child])
      end

      it 'wraps the children in a view without reps access' do
        expect(subject.children.map(&:class)).to eql([Nanoc::ItemWithoutRepsView])
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

  describe '#filter' do
    subject { rule_context.filter(filter_name, filter_args) }

    let(:filter_name) { :donkey }
    let(:filter_args) { { color: 'grey' } }

    it 'makes a request to the executor' do
      expect(executor).to receive(:filter).with(filter_name, filter_args)
      subject
    end
  end

  describe '#layout' do
    subject { rule_context.layout(layout_identifier, extra_filter_args) }

    let(:layout_identifier) { '/default.*' }
    let(:extra_filter_args) { { color: 'grey' } }

    it 'makes a request to the executor' do
      expect(executor).to receive(:layout).with(layout_identifier, extra_filter_args)
      subject
    end
  end

  describe '#snapshot' do
    subject { rule_context.snapshot(snapshot_name, path: path) }

    let(:snapshot_name) { :for_snippet }
    let(:path) { '/foo.html' }

    it 'makes a request to the executor' do
      expect(executor).to receive(:snapshot).with(:for_snippet, path: '/foo.html')
      subject
    end
  end

  describe '#write' do
    context 'with path' do
      context 'calling once' do
        subject { rule_context.write('/foo.html') }

        it 'makes a request to the executor' do
          expect(executor).to receive(:snapshot).with(:_0, path: '/foo.html')
          subject
        end
      end

      context 'calling twice' do
        subject do
          rule_context.write('/foo.html')
          rule_context.write('/bar.html')
        end

        it 'makes two requests to the executor with unique snapshot names' do
          expect(executor).to receive(:snapshot).with(:_0, path: '/foo.html')
          expect(executor).to receive(:snapshot).with(:_1, path: '/bar.html')
          subject
        end
      end
    end

    context 'with :ext, without period' do
      context 'calling once' do
        subject { rule_context.write(ext: 'html') }

        it 'makes a request to the executor' do
          expect(executor).to receive(:snapshot).with(:_0, path: '/foo.html')
          subject
        end
      end

      context 'calling twice' do
        subject do
          rule_context.write(ext: 'html')
          rule_context.write(ext: 'htm')
        end

        it 'makes a request to the executor' do
          expect(executor).to receive(:snapshot).with(:_0, path: '/foo.html')
          expect(executor).to receive(:snapshot).with(:_1, path: '/foo.htm')
          subject
        end
      end
    end

    context 'with :ext, without period' do
      context 'calling once' do
        subject { rule_context.write(ext: '.html') }

        it 'makes a request to the executor' do
          expect(executor).to receive(:snapshot).with(:_0, path: '/foo.html')
          subject
        end
      end

      context 'calling twice' do
        subject do
          rule_context.write(ext: '.html')
          rule_context.write(ext: '.htm')
        end

        it 'makes a request to the executor' do
          expect(executor).to receive(:snapshot).with(:_0, path: '/foo.html')
          expect(executor).to receive(:snapshot).with(:_1, path: '/foo.htm')
          subject
        end
      end
    end
  end
end
