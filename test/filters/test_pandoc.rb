# encoding: utf-8

class Nanoc::Filters::PandocTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'pandoc-ruby' do
      # Create filter
      filter = ::Nanoc::Filters::Pandoc.new

      # Run filter
      result = filter.run("# Heading")
      assert_equal("<h1 id=\"heading\">Heading</h1>", result)
    end
  end

end
