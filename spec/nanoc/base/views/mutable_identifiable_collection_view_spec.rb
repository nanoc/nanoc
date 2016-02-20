shared_examples 'a mutable identifiable collection' do
  let(:view) { described_class.new(wrapped_with_deletions, view_context) }

  let(:wrapped_with_deletions) do
    Nanoc::Int::IdentifiableCollectionWithModifications.new(
      wrapped,
    )
  end

  let(:deleted_identifiers) { Set.new }

  let(:view_context) { double(:view_context) }

  let(:config) do
    {}
  end

  describe '#delete_if' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |coll|
        coll << double(:identifiable, identifier: Nanoc::Identifier.new('/asdf/'))
      end
    end

    it 'does not delete matching' do
      view.delete_if { |i| i.identifier == '/asdf/' }
      expect(wrapped).not_to be_empty
    end

    it 'marks matching as deleted' do
      view.delete_if { |i| i.identifier == '/asdf/' }
      expect(wrapped_with_deletions).to be_empty
    end

    it 'does not delete non-matching' do
      view.delete_if { |i| i.identifier == '/blah/' }
      expect(wrapped).not_to be_empty
    end

    it 'does not mark non-matching as deleted' do
      view.delete_if { |i| i.identifier == '/blah/' }
      expect(wrapped_with_deletions).not_to be_empty
    end

    it 'returns self' do
      ret = view.delete_if { |_i| false }
      expect(ret).to equal(view)
    end

    it 'yields items with the proper context' do
      view.delete_if { |i| expect(i._context).to equal(view_context) }
    end
  end
end
