require 'helper'

class Nanoc::CLI::ExtTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_string_wrap_and_indent
    assert_equal(
      "Lorem ipsum dolor sit amet, consectetur\n" + 
      "adipisicing elit, sed do eiusmod tempor\n" + 
      "incididunt ut labore et dolore magna\n" + 
      "aliqua.",
      "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.".wrap_and_indent(40, 0)
    )

    assert_equal(
      "    Lorem ipsum dolor sit amet,\n" + 
      "    consectetur adipisicing elit, sed\n" + 
      "    do eiusmod tempor incididunt ut\n" + 
      "    labore et dolore magna aliqua.",
      "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.".wrap_and_indent(36, 4)
    )
  end

end
