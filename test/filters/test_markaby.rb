# encoding: utf-8

class Nanoc::Filters::MarkabyTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    # Don’t run this test on 1.9.x, because it breaks and it annoys me
    if RUBY_VERSION >= '1.9'
      skip "Markaby is not compatible with 1.9.x"
      return
    end

    if_have 'markaby' do
      # Create filter
      filter = ::Nanoc::Filters::Markaby.new

      # Run filter
      result = filter.run("html do\nend")
      assert_equal("<html></html>", result)
    end
  end

end
