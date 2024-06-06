# frozen_string_literal: true

describe Nanoc::Core::PostCompileItemView do
  let(:item) { Nanoc::Core::Item.new('blah', {}, '/foo.md') }
  let(:rep_a) { Nanoc::Core::ItemRep.new(item, :no_mod) }
  let(:rep_b) { Nanoc::Core::ItemRep.new(item, :modded).tap { |r| r.modified = true } }

  let(:reps) do
    Nanoc::Core::ItemRepRepo.new.tap do |reps|
      reps << rep_a
      reps << rep_b
    end
  end

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
    )
  end

  let(:items) { Nanoc::Core::ItemCollection.new(config, []) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config, []) }

  let(:view_context) do
    Nanoc::Core::ViewContextForCompilation.new(
      reps:,
      items: Nanoc::Core::ItemCollection.new(config),
      dependency_tracker: Nanoc::Core::DependencyTracker::Null.new,
      compilation_context:,
      compiled_content_store:,
    )
  end

  let(:compilation_context) do
    Nanoc::Core::CompilationContext.new(
      action_provider:,
      reps:,
      site:,
      compiled_content_cache:,
      compiled_content_store:,
    )
  end

  let(:action_provider) do
    Class.new(Nanoc::Core::ActionProvider) do
      def self.for(_context)
        raise NotImplementedError
      end

      def initialize; end
    end.new
  end

  let(:compiled_content_cache) { Nanoc::Core::CompiledContentCache.new(config:) }
  let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }

  let(:view) { described_class.new(item, view_context) }

  shared_examples 'a method that returns modified reps only' do
    it 'returns only modified items' do
      expect(subject.size).to eq(1)
      expect(subject.map(&:name)).to eq(%i[modded])
    end

    it 'returns an array' do
      expect(subject.class).to eql(Array)
    end
  end

  shared_examples 'a method that returns PostCompileItemRepViews' do
    it 'returns PostCompileItemRepViews' do
      expect(subject).to all(be_a(Nanoc::Core::PostCompileItemRepView))
    end
  end

  describe '#modified_reps' do
    subject { view.modified_reps }

    it_behaves_like 'a method that returns modified reps only'
    it_behaves_like 'a method that returns PostCompileItemRepViews'
  end

  describe '#modified' do
    subject { view.modified }

    it_behaves_like 'a method that returns modified reps only'
    it_behaves_like 'a method that returns PostCompileItemRepViews'
  end

  describe '#reps' do
    subject { view.reps }

    it_behaves_like 'a method that returns PostCompileItemRepViews'

    it 'returns a PostCompileItemRepCollectionView' do
      expect(subject).to be_a(Nanoc::Core::PostCompileItemRepCollectionView)
    end
  end
end
