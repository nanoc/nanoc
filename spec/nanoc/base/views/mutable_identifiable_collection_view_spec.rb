# frozen_string_literal: true

shared_examples 'a mutable identifiable collection' do
  let(:view) { described_class.new(wrapped, view_context) }

  let(:view_context) { double(:view_context) }

  let(:config) do
    {}
  end

  describe '#delete_if' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(
        config,
        [double(:identifiable, identifier: Nanoc::Identifier.new('/asdf/'))],
      )
    end

    it 'deletes matching' do
      view.delete_if { |i| i.identifier == '/asdf/' }
      expect(view.unwrap).to be_empty
    end

    it 'does not mutate' do
      view.delete_if { |i| i.identifier == '/asdf/' }
      expect(wrapped).not_to be_empty
    end

    it 'deletes no non-matching' do
      view.delete_if { |i| i.identifier == '/blah/' }
      expect(wrapped).not_to be_empty
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
