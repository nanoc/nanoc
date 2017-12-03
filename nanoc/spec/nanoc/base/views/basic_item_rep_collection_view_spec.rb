# frozen_string_literal: true

require_relative 'support/item_rep_collection_view_examples'

describe Nanoc::BasicItemRepCollectionView do
  it_behaves_like 'an item rep collection view'
  let(:expected_view_class) { Nanoc::BasicItemRepView }
end
