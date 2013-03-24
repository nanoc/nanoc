# encoding: utf-8

class Nanoc::Filters::CodeRayTest < Nanoc::TestCase

  def test_filter_without_language
    if_have 'coderay' do
      # Get filter
      filter = ::Nanoc::Filters::CodeRay.new

      # Run filter
      code = "def some_function ; x = blah.foo ; x.bar 'xyzzy' ; end"
      assert_raises(ArgumentError) do
        filter.setup_and_run(code)
      end
    end
  end

  def test_filter_with_known_language
    if_have 'coderay' do
      # Get filter
      filter = ::Nanoc::Filters::CodeRay.new

      # Run filter
      code = "def some_function ; x = blah.foo ; x.bar 'xyzzy' ; end"
      result = filter.setup_and_run(code, :language => 'ruby')
      assert_match %r{^<span class="keyword">def</span> <span class="function">some_function</span>}, result
    end
  end

  def test_filter_with_unknown_language
    if_have 'coderay' do
      # Get filter
      filter = ::Nanoc::Filters::CodeRay.new

      # Run filter
      code = "def some_function ; x = blah.foo ; x.bar 'xyzzy' ; end"
      result = filter.setup_and_run(code, :language => 'skldfhjsdhfjszfnocmluhfixfmersumulh')
      assert_equal code, result
    end
  end

end
