# encoding: utf-8

class Nanoc::Filters::MarukuTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'maruku' do
      # Create filter
      filter = ::Nanoc::Filters::Maruku.new

      # Run filter
      result = filter.run("This is _so_ *cool*!")
      assert_equal("<p>This is <em>so</em> <em>cool</em>!</p>", result)
    end
  end

end
