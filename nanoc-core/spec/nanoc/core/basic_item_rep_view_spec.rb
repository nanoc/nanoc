# frozen_string_literal: true

require_relative 'support/item_rep_view_examples'

describe Nanoc::Core::BasicItemRepView do
  let(:expected_item_view_class) { Nanoc::Core::BasicItemView }

  it_behaves_like 'an item rep view'
end
