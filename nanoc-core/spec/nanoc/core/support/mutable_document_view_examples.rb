# frozen_string_literal: true

shared_examples 'a mutable document view' do
  let(:view) { described_class.new(document, view_context) }

  let(:view_context) do
    Nanoc::Core::ViewContextForCompilation.new(
      reps: Nanoc::Core::ItemRepRepo.new,
      items: Nanoc::Core::ItemCollection.new(config),
      dependency_tracker:,
      compilation_context:,
      compiled_content_store:,
    )
  end

  let(:dependency_tracker) { Nanoc::Core::DependencyTracker.new(double(:dependency_store)) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:items) { Nanoc::Core::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }
  let(:reps) { Nanoc::Core::ItemRepRepo.new }

  let(:compilation_context) do
    Nanoc::Core::CompilationContext.new(
      action_provider:,
      reps:,
      site:,
      compiled_content_cache:,
      compiled_content_store:,
    )
  end

  let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }
  let(:compiled_content_cache) { Nanoc::Core::CompiledContentCache.new(config:) }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
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

  describe '#raw_content=' do
    let(:document) { entity_class.new('content', {}, '/asdf') }

    it 'sets raw content' do
      expect { view.raw_content = 'donkey' }
        .to change { document.content.string }
        .from('content')
        .to('donkey')
    end

    context 'checksum_data set' do
      before do
        document.checksum_data = 'my checksum data'
        document.content_checksum_data = 'my content checksum data'
        document.attributes_checksum_data = 'my attributes checksum data'
      end

      it 'unsets checksum_data' do
        expect { view.raw_content = 'donkey' }
          .to change(document, :checksum_data)
          .from('my checksum data')
          .to(nil)
      end

      it 'unsets content_checksum_data' do
        expect { view.raw_content = 'donkey' }
          .to change(document, :content_checksum_data)
          .from('my content checksum data')
          .to(nil)
      end

      it 'keeps attributes_checksum_data' do
        expect { view.raw_content = 'donkey' }
          .not_to change(document, :attributes_checksum_data)
      end
    end
  end

  describe '#[]=' do
    let(:document) { entity_class.new('content', {}, '/asdf') }

    it 'sets attributes' do
      view[:title] = 'Donkey'
      expect(view[:title]).to eq('Donkey')
    end

    it 'disallows items' do
      item = Nanoc::Core::Item.new('content', {}, '/foo.md')
      expect { view[:item] = item }.to raise_error(Nanoc::Core::MutableDocumentViewMixin::DisallowedAttributeValueError)
    end

    it 'disallows layouts' do
      layout = Nanoc::Core::Layout.new('content', {}, '/foo.md')
      expect { view[:layout] = layout }.to raise_error(Nanoc::Core::MutableDocumentViewMixin::DisallowedAttributeValueError)
    end

    it 'disallows item views' do
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('content', {}, '/foo.md'), nil)
      expect { view[:item] = item }.to raise_error(Nanoc::Core::MutableDocumentViewMixin::DisallowedAttributeValueError)
    end

    it 'disallows layout views' do
      layout = Nanoc::Core::LayoutView.new(Nanoc::Core::Layout.new('content', {}, '/foo.md'), nil)
      expect { view[:layout] = layout }.to raise_error(Nanoc::Core::MutableDocumentViewMixin::DisallowedAttributeValueError)
    end

    context 'checksum_data set' do
      before do
        document.checksum_data = 'my checksum data'
        document.content_checksum_data = 'my content checksum data'
        document.attributes_checksum_data = 'my attributes checksum data'
      end

      it 'unsets checksum_data' do
        expect { view[:title] = 'Donkey' }
          .to change(document, :checksum_data)
          .from('my checksum data')
          .to(nil)
      end

      it 'unsets attributes_checksum_data' do
        expect { view[:title] = 'Donkey' }
          .to change(document, :attributes_checksum_data)
          .from('my attributes checksum data')
          .to(nil)
      end

      it 'keeps content_checksum_data' do
        expect { view[:title] = 'Donkey' }
          .not_to change(document, :content_checksum_data)
      end
    end
  end

  describe '#identifier=' do
    subject { view.identifier = arg }

    let(:document) { entity_class.new('content', {}, '/about.md') }

    context 'given a string' do
      let(:arg) { '/about.adoc' }

      it 'changes the identifier' do
        subject
        expect(view.identifier).to eq('/about.adoc')
      end
    end

    context 'given an identifier' do
      let(:arg) { Nanoc::Core::Identifier.new('/about.adoc') }

      it 'changes the identifier' do
        subject
        expect(view.identifier).to eq('/about.adoc')
      end
    end

    context 'given anything else' do
      let(:arg) { :donkey }

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Core::Identifier::NonCoercibleObjectError)
      end
    end
  end

  describe '#update_attributes' do
    subject { view.update_attributes(update) }

    let(:document) { entity_class.new('content', {}, '/asdf') }

    let(:update) { { friend: 'Giraffe' } }

    it 'sets attributes' do
      expect { subject }.to change { view[:friend] }.from(nil).to('Giraffe')
    end

    it 'returns self' do
      expect(subject).to equal(view)
    end

    context 'checksum_data set' do
      before do
        document.checksum_data = 'my checksum data'
        document.content_checksum_data = 'my content checksum data'
        document.attributes_checksum_data = 'my attributes checksum data'
      end

      it 'unsets checksum_data' do
        expect { subject }
          .to change(document, :checksum_data)
          .from('my checksum data')
          .to(nil)
      end

      it 'unsets attributes_checksum_data' do
        expect { subject }
          .to change(document, :attributes_checksum_data)
          .from('my attributes checksum data')
          .to(nil)
      end

      it 'keeps content_checksum_data' do
        expect { subject }
          .not_to change(document, :content_checksum_data)
      end
    end
  end
end
