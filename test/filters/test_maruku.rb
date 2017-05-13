# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::MarukuTest < Nanoc::TestCase
  def test_filter
    if_have 'maruku' do
      # Create filter
      filter = ::Nanoc::Filters::Maruku.new

      # Run filter
      result = filter.setup_and_run('This is _so_ *cool*!')
      assert_equal('<p>This is <em>so</em> <em>cool</em>!</p>', result.strip)
    end
  end
end
