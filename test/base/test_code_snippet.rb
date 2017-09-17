# frozen_string_literal: true

require 'helper'

class Nanoc::Int::CodeSnippetTest < Nanoc::TestCase
  def test_load_with_toplevel_binding
    # Initialize
    @foo = 'meow'

    # Create code and load it
    code_snippet = Nanoc::Int::CodeSnippet.new("@foo = 'woof'", 'dog.rb')
    code_snippet.load

    # Ensure binding is correct
    assert_equal('meow', @foo)
  end
end
