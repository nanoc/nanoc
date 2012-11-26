# encoding: utf-8

class Nanoc::Filters::PandocTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'pandoc-ruby' do
      if `which pandoc`.strip.empty?
        skip "could not find pandoc"
      end

      # Create filter
      filter = ::Nanoc::Filters::Pandoc.new

      # Run filter
      result = filter.run("# Heading\n")
      assert_equal("<h1 id=\"heading\">Heading</h1>", result)
    end
  end

end
