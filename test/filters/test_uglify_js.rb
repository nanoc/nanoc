# encoding: utf-8

class Nanoc3::Filters::UglifyJSTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if_have 'uglifier' do
      # Create filter
      filter = ::Nanoc3::Filters::UglifyJS.new

      # Run filter
      result = filter.run("foo = 1; (function(bar) { if (true) alert(bar); })(foo)")
      assert_equal("foo=1,function(a){alert(a)}(foo)", result)
    end
  end

  def test_filter_with_options

    if_have 'uglifier' do
      # Create filter
      filter = ::Nanoc3::Filters::UglifyJS.new

      # Run filter
      result = filter.run("foo = 1; (function(bar) { if (true) alert(bar); })(foo)", :toplevel => true)
      assert_equal("foo=1,function(a){alert(a)}(foo)", result)
    end
  end

end
