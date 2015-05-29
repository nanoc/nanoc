class Nanoc::Int::RuleTest < Nanoc::TestCase
  def test_initialize
    # TODO: implement
  end

  def test_applicable_to
    # TODO: implement
  end

  def test_apply_to
    # TODO: implement
  end

  def test_matches
    pattern    = Nanoc::Int::Pattern.from(%r</(.*)/(.*)/>)
    identifier = '/anything/else/'
    expected   = ['anything', 'else']

    rule = Nanoc::Int::Rule.new(pattern, :string, Proc.new {})

    assert_equal expected, rule.send(:matches, identifier)
  end
end
