# encoding: utf-8

class Nanoc::PatternTest < Nanoc::TestCase

  def test_from_pattern
    pattern1 = Nanoc::Pattern.from('/foo/x[ab]z/bar.*')
    pattern2 = Nanoc::Pattern.from(pattern1)

    assert pattern2.match?('/foo/xaz/bar.html')
    refute pattern2.match?('/foo/xyz/bar.html')
  end

  def test_string
    pattern = Nanoc::Pattern.from('/foo/x[ab]z/bar.*')

    assert pattern.match?('/foo/xaz/bar.html')
    refute pattern.match?('/foo/xyz/bar.html')
  end

  def test_regex
    pattern = Nanoc::Pattern.from(%r{^/foo/(bar|baz)/qux})

    assert pattern.match?('/foo/bar/qux')
    refute pattern.match?('/foo/xyz/qux')
  end

end
