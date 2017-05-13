# frozen_string_literal: true

shared_examples 'a mutable document view' do
  let(:view) { described_class.new(document, view_context) }

  let(:view_context) do
    Nanoc::ViewContext.new(
      reps: double(:reps),
      items: double(:items),
      dependency_tracker: dependency_tracker,
      compilation_context: double(:compilation_context),
      snapshot_repo: snapshot_repo,
    )
  end

  let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(double(:dependency_store)) }
  let(:snapshot_repo) { double(:snapshot_repo) }

  describe '#raw_content=' do
    let(:document) { entity_class.new('content', {}, '/asdf/') }

    it 'sets raw content' do
      expect { view.raw_content = 'donkey' }
        .to change { document.content.string }
        .from('content')
        .to('donkey')
    end
  end

  describe '#[]=' do
    let(:document) { entity_class.new('content', {}, '/asdf/') }

    it 'sets attributes' do
      view[:title] = 'Donkey'
      expect(view[:title]).to eq('Donkey')
    end

    it 'disallows items' do
      item = Nanoc::Int::Item.new('content', {}, '/foo.md')
      expect { view[:item] = item }.to raise_error(Nanoc::MutableDocumentViewMixin::DisallowedAttributeValueError)
    end

    it 'disallows layouts' do
      layout = Nanoc::Int::Layout.new('content', {}, '/foo.md')
      expect { view[:layout] = layout }.to raise_error(Nanoc::MutableDocumentViewMixin::DisallowedAttributeValueError)
    end

    it 'disallows item views' do
      item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('content', {}, '/foo.md'), nil)
      expect { view[:item] = item }.to raise_error(Nanoc::MutableDocumentViewMixin::DisallowedAttributeValueError)
    end

    it 'disallows layout views' do
      layout = Nanoc::LayoutView.new(Nanoc::Int::Layout.new('content', {}, '/foo.md'), nil)
      expect { view[:layout] = layout }.to raise_error(Nanoc::MutableDocumentViewMixin::DisallowedAttributeValueError)
    end
  end

  describe '#identifier=' do
    let(:document) { entity_class.new('content', {}, '/about.md') }

    subject { view.identifier = arg }

    context 'given a string' do
      let(:arg) { '/about.adoc' }

      it 'changes the identifier' do
        subject
        expect(view.identifier).to eq('/about.adoc')
      end
    end

    context 'given an identifier' do
      let(:arg) { Nanoc::Identifier.new('/about.adoc') }

      it 'changes the identifier' do
        subject
        expect(view.identifier).to eq('/about.adoc')
      end
    end

    context 'given anything else' do
      let(:arg) { :donkey }

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Identifier::NonCoercibleObjectError)
      end
    end
  end

  describe '#update_attributes' do
    let(:document) { entity_class.new('content', {}, '/asdf/') }

    let(:update) { { friend: 'Giraffe' } }

    subject { view.update_attributes(update) }

    it 'sets attributes' do
      expect { subject }.to change { view[:friend] }.from(nil).to('Giraffe')
    end

    it 'returns self' do
      expect(subject).to equal(view)
    end
  end
end
