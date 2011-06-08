# encoding: utf-8

class Nanoc3::Filters::CodeRayTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter_without_language
    if_have 'coderay' do
      # Get filter
      filter = ::Nanoc3::Filters::CodeRay.new

      # Run filter
      code = "def some_function ; x = blah.foo ; x.bar 'xyzzy' ; end"
      assert_raises(ArgumentError) do
        filter.run(code)
      end
    end
  end

  def test_filter_with_known_language
    if_have 'coderay' do
      # Get filter
      filter = ::Nanoc3::Filters::CodeRay.new

      # Run filter
      code = "def some_function ; x = blah.foo ; x.bar 'xyzzy' ; end"
      result = filter.run(code, :language => 'ruby')
      assert_match %r{^<span class="r">def</span> <span class="fu">some_function</span>}, result
    end
  end

  def test_filter_with_unknown_language
    if_have 'coderay' do
      # Get filter
      filter = ::Nanoc3::Filters::CodeRay.new

      # Run filter
      code = "def some_function ; x = blah.foo ; x.bar 'xyzzy' ; end"
      result = filter.run(code, :language => 'skldfhjsdhfjszfnocmluhfixfmersumulh')
      assert_equal code, result
    end
  end

end
