shared_examples 'a mutable document view' do
  describe '#[]=' do
    let(:item) { entity_class.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item, nil) }

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
      item = Nanoc::ItemView.new(Nanoc::Int::Item.new('content', {}, '/foo.md'), nil)
      expect { view[:item] = item }.to raise_error(Nanoc::MutableDocumentViewMixin::DisallowedAttributeValueError)
    end

    it 'disallows layout views' do
      layout = Nanoc::LayoutView.new(Nanoc::Int::Layout.new('content', {}, '/foo.md'), nil)
      expect { view[:layout] = layout }.to raise_error(Nanoc::MutableDocumentViewMixin::DisallowedAttributeValueError)
    end
  end

  describe '#update_attributes' do
    let(:item) { entity_class.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item, nil) }

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
