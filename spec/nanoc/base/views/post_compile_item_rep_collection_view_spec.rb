# frozen_string_literal: true

describe Nanoc::PostCompileItemRepCollectionView do
  it_behaves_like 'an item rep collection view'
  let(:expected_view_class) { Nanoc::PostCompileItemRepView }
end
