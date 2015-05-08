# encoding: utf-8

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
    regexp     = %r</(.*)/(.*)/>
    identifier = '/anything/else/'
    expected   = ['anything', 'else']

    rule = Nanoc::Int::Rule.new(regexp, :string, Proc.new {})

    assert_equal expected, rule.send(:matches, identifier)
  end
end
