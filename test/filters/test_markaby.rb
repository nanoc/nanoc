require 'test/helper'

class Nanoc3::Filters::MarkabyTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if_have 'markaby' do
      # Create filter
      filter = ::Nanoc3::Filters::Markaby.new

      # Run filter
      result = filter.run("html do\nend")
      assert_equal("<html></html>", result)
    end
  end

end
