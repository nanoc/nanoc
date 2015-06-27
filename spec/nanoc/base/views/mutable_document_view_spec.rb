shared_examples 'a mutable document view' do
  let(:view) { described_class.new(document, reps) }

  let(:reps) { double(:reps) }

  describe '#[]=' do
    let(:document) { entity_class.new('content', {}, '/asdf/') }

    it 'sets attributes' do
      view[:title] = 'Donkey'
      expect(view[:title]).to eq('Donkey')
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
