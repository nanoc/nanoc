shared_examples 'a mutable identifiable collection' do
  let(:view) { described_class.new(wrapped) }

  let(:config) do
    {}
  end

  describe '#delete_if' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |coll|
        coll << double(:identifiable, identifier: Nanoc::Identifier.new('/asdf/'))
      end
    end

    it 'deletes matching' do
      view.delete_if { |i| i.identifier == '/asdf/' }
      expect(wrapped).to be_empty
    end

    it 'deletes no non-matching' do
      view.delete_if { |i| i.identifier == '/blah/' }
      expect(wrapped).not_to be_empty
    end

    it 'returns self' do
      ret = view.delete_if { |_i| false }
      expect(ret).to equal(view)
    end
  end
end
