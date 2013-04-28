# encoding: utf-8

class Nanoc::IdentifierTest < Nanoc::TestCase

  def new_from_string(string)
    Nanoc::Identifier.from_string(string)
  end

  def test_from_string
    assert_equal %w( ), self.new_from_string('').components
    assert_equal %w( ), self.new_from_string('/').components

    assert_equal %w( foo bar ), self.new_from_string('foo/bar').components
    assert_equal %w( foo bar ), self.new_from_string('foo/bar/').components
    assert_equal %w( foo bar ), self.new_from_string('/foo/bar').components
    assert_equal %w( foo bar ), self.new_from_string('/foo/bar/').components
  end

  def test_equal
    a = self.new_from_string('/foo/bar')
    b = self.new_from_string('foo/bar')

    refute a.equal?(b)

    assert a.eql?(b)
    assert a == b
    assert a === b
  end

  def test_to_s
    assert_equal '/foo/bar/', self.new_from_string('/foo/bar/').to_s
    assert_equal '/foo/',     self.new_from_string('/foo/').to_s
    assert_equal '/',         self.new_from_string('/').to_s
  end

  def test_parent
    assert_equal '/foo/bar/', self.new_from_string('foo/bar/qux').parent.to_s
    assert_equal '/foo/',     self.new_from_string('foo/bar').parent.to_s
    assert_equal '/',         self.new_from_string('foo').parent.to_s
    assert_nil self.new_from_string('/').parent
  end

  def test_plus
    assert_equal '/foo/xyz', self.new_from_string('/foo/') + 'xyz'
  end

  def test_chop
    assert_equal '/foo', self.new_from_string('/foo/').chop
  end

end
