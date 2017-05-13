# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::MarkabyTest < Nanoc::TestCase
  def test_filter
    if_have 'markaby' do
      # Create filter
      filter = ::Nanoc::Filters::Markaby.new

      # Run filter
      result = filter.setup_and_run("html do\nend")
      assert_equal('<html></html>', result)
    end
  end
end
