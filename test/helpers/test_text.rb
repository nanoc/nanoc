require 'helper'

class Nanoc::Helpers::TextTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Helpers::Text

  def test_excerpt_length
    assert_equal('...',                         excerpt('Foo bar baz quux meow woof', :length => 3))
    assert_equal('Foo ...',                     excerpt('Foo bar baz quux meow woof', :length => 7))
    assert_equal('Foo bar baz quux meow woof',  excerpt('Foo bar baz quux meow woof', :length => 26))
    assert_equal('Foo bar baz quux meow woof',  excerpt('Foo bar baz quux meow woof', :length => 8623785))
  end

  def test_excerpt_omission
    assert_equal('Foo [continued]',             excerpt('Foo bar baz quux meow woof', :length => 15, :omission => '[continued]'))
  end

end
