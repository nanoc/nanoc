# frozen_string_literal: true

describe Nanoc::CompilationItemRepCollectionView do
  it_behaves_like 'an item rep collection view'
  let(:expected_view_class) { Nanoc::CompilationItemRepView }
end
