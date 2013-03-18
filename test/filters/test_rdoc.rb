# encoding: utf-8

class Nanoc::Filters::RDocTest < Nanoc::TestCase

  def test_filter
    if_have 'rdoc' do
      # Get filter
      filter = ::Nanoc::Filters::RDoc.new

      # Run filter
      result = filter.setup_and_run("= Foo")
      assert_match(%r{<h1( id="label-Foo")?>Foo</h1>\Z}, result)
    end
  end

end
