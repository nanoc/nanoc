# encoding: utf-8

class Nanoc::Filters::RDocTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'rdoc' do
      # Get filter
      filter = ::Nanoc::Filters::RDoc.new

      # Run filter
      result = filter.run("= Foo")
      assert_match(%r{<h1( id="label-Foo")?>Foo</h1>\Z}, result)
    end
  end

end
