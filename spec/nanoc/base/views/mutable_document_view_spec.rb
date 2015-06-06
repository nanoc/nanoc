shared_examples 'a mutable document view' do
  describe '#[]=' do
    let(:item) { entity_class.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item) }

    it 'sets attributes' do
      view[:title] = 'Donkey'
      expect(view[:title]).to eq('Donkey')
    end
  end

  describe '#update_attributes' do
    let(:item) { entity_class.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item) }

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
