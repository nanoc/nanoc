# encoding: utf-8

class Nanoc::Filters::UglifyJSTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'uglifier' do
      # Create filter
      filter = ::Nanoc::Filters::UglifyJS.new

      # Run filter
      result = filter.run("foo = 1; (function(bar) { if (true) alert(bar); })(foo)")
      assert_equal("foo=1,function(e){alert(e)}(foo);", result)
    end
  end

  def test_filter_with_options

    if_have 'uglifier' do
      # Create filter
      filter = ::Nanoc::Filters::UglifyJS.new

      # Run filter
      result = filter.run("foo = 1; (function(bar) { if (true) alert(bar); })(foo)", :toplevel => true)
      assert_equal("foo=1,function(e){alert(e)}(foo);", result)
    end
  end

end
