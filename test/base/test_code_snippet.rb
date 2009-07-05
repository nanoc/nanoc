# encoding: utf-8

require 'test/helper'

class Nanoc3::CodeSnippetTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_load
    # Initialize
    $complete_insane_parrot = 'meow'

    # Create code and load it
    code_snippet = Nanoc3::CodeSnippet.new("$complete_insane_parrot = 'woof'", 'parrot.rb')
    code_snippet.load

    # Ensure code is loaded
    assert_equal('woof', $complete_insane_parrot)
  end

  def test_load_with_toplevel_binding
    # Initialize
    @foo = 'meow'

    # Create code and load it
    code_snippet = Nanoc3::CodeSnippet.new("@foo = 'woof'", 'dog.rb')
    code_snippet.load

    # Ensure binding is correct
    assert_equal('meow', @foo)
  end

end
